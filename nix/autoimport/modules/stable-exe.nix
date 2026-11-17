# `jl.stableExe.<name>`: run a command-line binary from a fixed path outside
# the store so macOS permission grants survive upgrades (Darwin only).
#
# macOS TCC (Accessibility, Files and Folders, ...) tracks a bare executable by
# its absolute path. A store path changes with every version, so each upgrade
# shows up as a new, ungranted entry. Activation copies the real binary to
# ~/.local/state/stable-exe/<name>/<name> and `finalPackage` swaps the command
# bin/<name> for a launcher that execs that copy. <name> is also what macOS
# shows in System Settings.
#
# The grant also pins the code signature. A vendor-signed binary (claude) is
# fine as is; one built from source is ad-hoc signed and additionally needs
# `pkgs.signStable` (see sign-stable.nix). App bundles are tracked by bundle
# id, not path, so they only ever need signStable.
#
#   jl.stableExe.foo.package = pkgs.foo;
#   home.packages = [config.jl.stableExe.foo.finalPackage];
#
# On Linux `finalPackage` is `package`, so callers need no platform branch.
{
  flake.modules.homeManager.base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    # Relative to $HOME: the launcher resolves it at run time.
    stateDir = name: ".local/state/stable-exe/${name}";
    sourceOf = e: "${e.package}/${e.exe}";
  in {
    options.jl.stableExe = lib.mkOption {
      default = {};
      description = "Binaries to run from a stable path so macOS grants persist.";
      type = lib.types.attrsOf (lib.types.submodule ({
        name,
        config,
        ...
      }: {
        options = {
          package = lib.mkOption {type = lib.types.package;};
          exe = lib.mkOption {
            type = lib.types.str;
            default = "bin/${name}";
            description = ''
              The real Mach-O, relative to the package. Differs from bin/<name>
              when that is a wrapper, e.g. "bin/.foo-unwrapped".
            '';
          };
          prefixPath = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = ''
              Packages to put on PATH. The launcher bypasses the package's own
              wrapper, so repeat here whatever that wrapper added.
            '';
          };
          finalPackage = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            default =
              if !isDarwin
              then config.package
              else
                pkgs.symlinkJoin {
                  name = "${config.package.name}-stable";
                  meta = config.package.meta or {};
                  # First path wins, so the launcher shadows the command.
                  paths = [
                    (pkgs.writeTextFile {
                      name = "${name}-launcher";
                      destination = "/bin/${name}";
                      executable = true;
                      # Falls back to the store binary when the copy is missing
                      # or belongs to another generation (before first
                      # activation, `nix run`, rollbacks), so the command never
                      # breaks.
                      text = ''
                        #!/bin/sh
                        ${lib.optionalString (config.prefixPath != []) ''export PATH="${lib.makeBinPath config.prefixPath}:$PATH"''}
                        d="$HOME/${stateDir name}"
                        src="${sourceOf config}"
                        if [ -r "$d/source" ] && read -r cur < "$d/source" && [ "$cur" = "$src" ]; then
                          exec "$d/${name}" "$@"
                        fi
                        exec "$src" "$@"
                      '';
                    })
                    config.package
                  ];
                };
          };
        };
      }));
    };

    config.home.activation.stableExe = lib.mkIf (isDarwin && config.jl.stableExe != {}) (
      lib.hm.dag.entryAfter ["writeBoundary"] (
        lib.concatStrings (lib.mapAttrsToList (name: e: ''
            d=${lib.escapeShellArg "${config.home.homeDirectory}/${stateDir name}"}
            src=${lib.escapeShellArg (sourceOf e)}
            if [ "$(cat "$d/source" 2>/dev/null)" != "$src" ]; then
              # Marker cleared first and written last, so a launcher never
              # matches a binary from another generation. Copy then rename:
              # processes still running the old binary keep their file, and
              # the launcher never sees a half-written one.
              run rm -f "$d/source"
              run install -Dm755 "$src" "$d/.new"
              run mv -f "$d/.new" "$d"/${lib.escapeShellArg name}
              run sh -c 'echo "$1" > "$2"' _ "$src" "$d/source"
            fi
          '')
          config.jl.stableExe)
      )
    );
  };
}

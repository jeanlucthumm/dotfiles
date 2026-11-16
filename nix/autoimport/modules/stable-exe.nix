# `jl.stableExe.<name>`: run a command-line binary from a fixed path outside
# the store so macOS permission grants survive upgrades (Darwin only).
#
# macOS TCC (Accessibility, Files and Folders, ...) tracks a bare executable by
# its absolute path. A store path changes with every version, so each upgrade
# shows up as a new, ungranted entry. Activation copies the real binary to
# ~/.local/state/stable-exe/<name>/<bin> and `finalPackage` swaps the command
# for a launcher that execs that copy.
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
    stateDir = "${config.home.homeDirectory}/.local/state/stable-exe";
    entries = lib.attrValues config.jl.stableExe;
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
          bin = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Command name under bin/; also the name macOS shows.";
          };
          exe = lib.mkOption {
            type = lib.types.str;
            default = "bin/${config.bin}";
            description = ''
              The real Mach-O, relative to the package. Differs from bin/<bin>
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
          source = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            default = "${config.package}/${config.exe}";
          };
          stablePath = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            default = "${stateDir}/${name}/${config.bin}";
          };
          finalPackage = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            default =
              if !isDarwin
              then config.package
              else
                pkgs.runCommand "${config.package.name}-stable" {
                  meta = config.package.meta or {};
                  # Falls back to the store binary when the copy is missing or
                  # belongs to another generation (before first activation,
                  # `nix run`, rollbacks), so the command never breaks.
                  launcher = ''
                    #!/bin/sh
                    ${lib.optionalString (config.prefixPath != []) ''export PATH="${lib.makeBinPath config.prefixPath}:$PATH"''}
                    d="$HOME/.local/state/stable-exe/${name}"
                    if [ -r "$d/source" ] && read -r src < "$d/source" && [ "$src" = "${config.source}" ]; then
                      exec "$d/${config.bin}" "$@"
                    fi
                    exec "${config.source}" "$@"
                  '';
                  passAsFile = ["launcher"];
                } ''
                  mkdir -p $out/bin
                  for p in ${config.package}/*; do
                    [ "$(basename "$p")" = bin ] || ln -s "$p" $out/
                  done
                  for p in ${config.package}/bin/*; do
                    ln -s "$p" $out/bin/
                  done
                  rm -f $out/bin/${config.bin}
                  cp "$launcherPath" $out/bin/${config.bin}
                  chmod +x $out/bin/${config.bin}
                '';
          };
        };
      }));
    };

    config.home.activation.stableExe = lib.mkIf (isDarwin && entries != []) (
      lib.hm.dag.entryAfter ["writeBoundary"] (
        lib.concatMapStrings (e: ''
          d=${lib.escapeShellArg (dirOf e.stablePath)}
          if [ "$(cat "$d/source" 2>/dev/null)" != ${lib.escapeShellArg e.source} ]; then
            run mkdir -p "$d"
            # Copy then rename: processes still running the old binary keep
            # their file, and the launcher never sees a half-written one.
            run rm -f "$d/source"
            run cp ${lib.escapeShellArg e.source} "$d/.new"
            run chmod 755 "$d/.new"
            run mv -f "$d/.new" ${lib.escapeShellArg e.stablePath}
            run sh -c 'printf "%s\n" "$1" > "$2"' _ ${lib.escapeShellArg e.source} "$d/source"
          fi
        '')
        entries
      )
    );
  };
}

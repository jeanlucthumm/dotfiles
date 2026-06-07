# Sets `pkgs` for all `perSystem` sets and allows for customization like overlays
fp @ {withSystem, ...}: {
  flake.modules.generic.base = {
    config,
    lib,
    ...
  }: {
    options.jl.system = lib.mkOption {
      type = lib.types.str;
      description = "System string";
    };

    config = {
      # Avoid evaluating `pkgs` multiple times by importing the one from flake-parts
      # for this system.
      nixpkgs.pkgs = withSystem config.jl.system ({pkgs, ...}: pkgs);
    };
  };

  # readOnlyPkgs forbids any module from setting nixpkgs.overlays/.config later.
  # NixOS-only: nix-darwin's own nixpkgs module declares config and
  # collides with readOnlyPkgs on Darwin.
  flake.modules.nixos.base = {
    imports = [fp.inputs.nixpkgs.nixosModules.readOnlyPkgs];
  };

  perSystem = {system, ...}: {
    _module.args.pkgs = import fp.inputs.nixpkgs {
      inherit system;
      config = {
        # Bite me
        allowUnfree = true;
        # TODO can't tell if we need this line. This is bc we have read-only nixpkgs, and
        # previously host config would do `nixpkgs.hostPlatform = ` which is not allowed.
        hostPlatform = system;
      };
      overlays = [
        (final: prev: {
          # Extend pkgs.sem (Semaphore CI CLI) to Darwin — upstream is pure Go and
          # ships Darwin arm64 binaries, but the nixpkgs meta restricts it to Linux.
          sem = prev.sem.overrideAttrs (old: {
            meta =
              old.meta
              // {
                platforms = old.meta.platforms ++ prev.lib.platforms.darwin;
              };
          });
        })

        # Darwin overrides
        (final: prev:
          prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
            # TODO: Remove once pysilero-vad > 3.3.0 lands in nixpkgs (nixpkgs#491459)
            # Upstream fix: rhasspy/pysilero-vad#15 (merged, but no release cut yet)
            # Darwin fixes
            python3 = prev.python3.override {
              packageOverrides = pyFinal: pyPrev: {
                pysilero-vad = pyPrev.pysilero-vad.overridePythonAttrs {
                  version = "3.3.0-unstable-2026-02-12";
                  src = prev.fetchFromGitHub {
                    owner = "rhasspy";
                    repo = "pysilero-vad";
                    rev = "d5fb763a592f5ffb633a494fd073ee93fe8b5445";
                    hash = "sha256-gQDZuu8hN0s+yfkp22w39/Aje5/6qdX0W95FPu6obw0=";
                    fetchSubmodules = true;
                  };
                };
              };
            };
            python3Packages = final.python3.pkgs;

            # Temporary: pull nushell from a pinned nixpkgs with the darwin test-skip fix.
            # Drop once inputs.nixpkgs catches up.
            nushell =
              (import fp.inputs.nixpkgs-nushell {
                inherit (prev.stdenv.hostPlatform) system;
              }).nushell;
          })
      ];
    };
  };
}

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
            # afdko 5.0.1's addfeatures hmtx optimizer underflows a size_t
            # (`size() - 2` when size < 2), which traps with SIGTRAP on darwin:
            # it fails afdko's own test suite and breaks consumers like nototools.
            # Backport the upstream one-line fix until our nixpkgs carries it
            # (already on nixpkgs master via commit bf959d333).
            # Fix: https://github.com/adobe-type-tools/afdko/pull/1843
            python3 = prev.python3.override {
              packageOverrides = pyFinal: pyPrev: {
                afdko = pyPrev.afdko.overridePythonAttrs (old: {
                  patches =
                    (old.patches or [])
                    ++ [
                      (prev.fetchpatch {
                        name = "afdko-addfeatures-hmtx-underflow.patch";
                        url = "https://github.com/adobe-type-tools/afdko/commit/91833ab6c1a769f82f30dbf126362d079905bfc6.patch";
                        hash = "sha256-GZtjJbqwR33CxpBpkcs6GaOztJ20QkFDVpvzT+Nh9EE=";
                      })
                    ];
                });
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

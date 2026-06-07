fp @ {jlib, ...}: {
  flake.modules.nixos.base = {pkgs, ...}: {
    # Basic system wide packages
    environment.systemPackages = with pkgs; [
      file # Figure out what a certain file is
      lsof # Open files (but good for ports)
      tmux # Terminal multiplexer
      git # Version control
      nushell # Shell so I don't have to use bash for sysadmin
      yadm # Dotfile manager
      zfs # ZFS filesystem tools
      vim # Text editor
    ];
  };

  flake.modules.darwin.base = {
    # Allow nushell as a login shell. Installed via home-manager, so it lives
    # under the per-user profile path.
    environment.shells = ["/etc/profiles/per-user/jeanluc/bin/nu"];
  };

  flake.modules.homeManager.base = {
    pkgs,
    lib,
    ...
  }:
    jlib.mkHomeManager {
      generic = {
        home.packages = [pkgs.nushell];

        programs.nushell = {
          enable = true;
          shellAliases = {
            vim = "nvim";
            fg = "job unfreeze";
            cd = "z";
            cat = "bat";
            man = "batman";
          };
          environmentVariables = {
            GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
          };
          settings = {
            completions.algorithm = "fuzzy";
          };
          extraConfig = builtins.concatStringsSep "\n" [
            (builtins.readFile ./scripts/config-base.nu)
            (builtins.readFile ./scripts/config-qol.nu)
          ];
        };

        # Custom integration in config-qol.nu with path fallback
        programs.carapace.enableNushellIntegration = false;
        programs.direnv.enableNushellIntegration = true;
        programs.yazi = {
          shellWrapperName = "y";
          enableNushellIntegration = true;
        };
        programs.zoxide.enableNushellIntegration = true;
      };

      nixos = {
        programs.nushell.extraConfig = builtins.concatStringsSep "\n" [
          (builtins.readFile ./scripts/nixos-config.nu)
          ''
            # TODO: switch back to nh once tty passthrough is fixed (~/Code/nh/issue.md)
            def nrs []: [nothing -> nothing] {
                sudo nixos-rebuild switch --flake ~/nix
                if "HW_KEY_HOST" in $env {
                  delock # decrypt agenix secrets (YubiKey PIN + touch)
                }
            }

            def nra []: [nothing -> nothing] {
                sudo nixos-rebuild switch --flake ~/nix --upgrade
                if "HW_KEY_HOST" in $env {
                  delock # decrypt agenix secrets (YubiKey PIN + touch)
                }
            }
          ''
        ];
      };

      darwin = {osConfig, ...}: {
        programs.nushell.extraConfig = ''
          def nrs []: [nothing -> nothing] {
              nh darwin switch -H ${osConfig.networking.hostName}
              if "HW_KEY_HOST" in $env {
                delock # decrypt agenix secrets (YubiKey PIN + touch)
              }
          }

          def nra []: [nothing -> nothing] {
              nh darwin switch -H ${osConfig.networking.hostName} -u
              if "HW_KEY_HOST" in $env {
                delock # decrypt agenix secrets (YubiKey PIN + touch)
              }
          }
        '';
      };
    };
}

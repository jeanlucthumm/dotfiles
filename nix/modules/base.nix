# Base for all module systems
{
  config,
  inputs,
  ...
}: {
  # Allows for setting `flake.modules`.
  # Only needs to be imported in one file per eval so base is natural fit.
  imports = [inputs.flake-parts.flakeModules.modules];

  flake.modules.generic.base = {
    nix = {
      enable = true;

      # Enable flakes
      settings.experimental-features = ["nix-command" "flakes"];
      # Increase download buffer to prevent "download buffer is full" errors
      settings.download-buffer-size = 134217728; # 128MB

      # Nix store gets full of old stuff, so clean it up periodically.
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };

    # Bite me
    nixpkgs.config.allowUnfree = true;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };

  flake.modules.nixos.base = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      config.flake.modules.generic.base
    ];

    # Timezone and locale
    time.timeZone = "America/Los_Angeles";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    security.sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };
  };

  flake.modules.darwin.base = {
    imports = [
      inputs.home-manager.darwinModules.home-manager
      config.flake.modules.generic.base
    ];

    system.defaults.NSGlobalDomain = {
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
    };

    system.defaults.CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          "34" = {
            # Show application windows (Ctrl+Down)
            enabled = true;
            value = {
              parameters = [65535 125 2359296];
              type = "standard";
            };
          };
          "27" = {
            # Move focus to next window (Cmd+`)
            enabled = true;
            value = {
              parameters = [96 50 1048576];
              type = "standard";
            };
          };
          "222" = {
            # Toggle Stage Manager (Cmd+Shift+I)
            enabled = true;
            value = {
              parameters = [105 34 1179648];
              type = "standard";
            };
          };
          # Disable Spotlight search (Cmd+Space)
          "64".enabled = false;
          # Disable Finder search window (Cmd+Option+Space)
          "65".enabled = false;
        };
      };
    };
  };

  flake.modules.homeManager = {
    base = {
      imports = [inputs.agenix.homeManagerModules.default];
    };

    nixos = {...}: {
      imports = [config.flake.modules.homeManager.base];
      programs = {
        nushell.configFile.text = ''
          # TODO: switch back to nh once tty passthrough is fixed (~/code/nh/issue.md)
          def nrs []: [nothing -> nothing] {
              sudo nixos-rebuild switch --flake ~/nix
          }

          def nra []: [nothing -> nothing] {
              sudo nixos-rebuild switch --flake ~/nix --upgrade
          }
        '';
      };
    };

    darwin = p: {
      imports = [config.flake.modules.homeManager.base];
      programs = {
        # TODO: delock should only be set if we are using agenix module
        nushell.configFile.text = ''
          def nrs []: [nothing -> nothing] {
              nh darwin switch -H ${p.osConfig.networking.hostName}
              delock # decrypt agenix secrets (YubiKey PIN + touch)
          }

          def nra []: [nothing -> nothing] {
              nh darwin switch -H ${p.osConfig.networking.hostName} -u
              delock # decrypt agenix secrets (YubiKey PIN + touch)
          }
        '';
      };

      home = {
        # Extra stuff to add to $PATH
        sessionPath = [
          # homebrew puts all its stuff in this directory instead
          # of /usr/bin or otherwise
          "/opt/homebrew/bin"
          # Any Dart dev requires this in path
          "${config.home.homeDirectory}/.pub-cache/bin"
        ];
      };
    };
  };
}

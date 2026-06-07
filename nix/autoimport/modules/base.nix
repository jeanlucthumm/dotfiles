# Base for all module systems
fp @ {jlib, ...}: {
  # Allows for setting `flake.modules`.
  # Only needs to be imported in one file per eval so base is natural fit.
  imports = [fp.inputs.flake-parts.flakeModules.modules];

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

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };

  flake.modules.nixos.base = {pkgs, ...}: {
    imports = [
      fp.config.flake.modules.generic.base
      fp.inputs.home-manager.nixosModules.home-manager
      fp.inputs.disko.nixosModules.disko
    ];

    environment.systemPackages = with pkgs; [
      deploy-rs
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

    boot = {
      loader = {
        # Allows NixOS to modify EFI variables, e.g. boot entries and order.
        efi.canTouchEfiVariables = true;
        # Bootloader
        systemd-boot = {
          enable = true;
          # CLI at the UEFI level. So you can interact with boot process to
          # fix things if neccessary.
          edk2-uefi-shell.enable = true;
          # Limits the amount of previous generations in the boot menu. If this is set to unlimited,
          # the /boot partition can fill up.
          configurationLimit = 20;
        };
      };
      supportedFilesystems = ["ntfs"];
    };

    # TODO: reconcile this with the full config for the server
    # All NixOS devices should be nodes
    services.syncthing.enable = true;

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.base];
  };

  flake.modules.darwin.base = {
    imports = [
      fp.inputs.home-manager.darwinModules.home-manager
      fp.config.flake.modules.generic.base
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

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.base];
  };

  flake.modules.homeManager.base = jlib.mkHomeManager {
    nixos = {
      services.hyprpolkitagent.enable = true;
    };
    darwin = {config, ...}: {
      home.sessionPath = [
        # Homebrew puts its stuff here instead of /usr/bin
        "/opt/homebrew/bin"
        # TODO: move this to dev
        # Any Dart dev requires this in path
        "${config.home.homeDirectory}/.pub-cache/bin"
      ];
    };
  };
}

{pkgs, ...}: {
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ./nginx.nix
    ./media.nix
    ../../modules/foundation.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/tailscale.nix
    ../../modules/user-jeanluc.nix
    ../../modules/boot.nix
    ../../modules/containers.nix
    ../../modules/home-assistant.nix
  ];

  networking.hostName = "server";
  networking.hostId = "1d9f895e";

  users.users.root = {
    openssh.authorizedKeys.keys = (import ../../../secrets/pubkeys.nix).all;
  };

  environment.systemPackages = with pkgs; [
    smartmontools # for disk health monitoring
  ];

  # ZFS auto-scrub (weekly data integrity checks)
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly"; # Run every Sunday at 2:00 AM
  };

  # Sanoid automated snapshots
  services.sanoid = {
    enable = true;
    interval = "hourly"; # Check for snapshots every hour

    templates = {
      # Template for critical data (backups)
      critical = {
        hourly = 24; # 1 day of hourly
        daily = 14; # 2 weeks of daily
        weekly = 4; # 1 month of weekly
      };

      # Template for large infrequent storage (media/games)
      storage = {
        daily = 7; # 1 week of daily
        weekly = 4; # 1 month of weekly
      };
    };

    datasets = {
      "tank/backups" = {
        useTemplate = ["critical"];
      };
      "tank/media" = {
        useTemplate = ["storage"];
      };
      "tank/games" = {
        useTemplate = ["storage"];
      };
      # Skip tank/tmp - it's temporary data
    };
  };

  services.atd.enable = true; # Enable the at daemon for scheduled tasks

  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024; # 8 GiB
    }
  ];
  system.stateVersion = "24.05";
}

{pkgs, ...}: {
  # Media group for shared access to media files
  users.groups.media = {};
  users.users.jeanluc.extraGroups = ["media"];

  services = {
    # Transmission BitTorrent client
    transmission = {
      enable = true;
      user = "transmission";
      group = "media";
      settings = {
        # Directories
        download-dir = "/srv/media/movies";
        incomplete-dir = "/srv/tmp";
        incomplete-dir-enabled = true;

        # File permissions (002 = group write access)
        umask = 2;

        # Connection limits for performance
        peer-limit-global = 200;
        peer-limit-per-torrent = 50;

        # Queue management
        download-queue-enabled = true;
        download-queue-size = 5;
        seed-queue-enabled = true;
        seed-queue-size = 10;

        # Speed limits
        speed-limit-down-enabled = false;
        speed-limit-up-enabled = false;

        # Protocol settings for better connectivity
        dht-enabled = true;
        pex-enabled = true;
        lpd-enabled = true;
        utp-enabled = true;

        # RPC (web interface)
        rpc-bind-address = "0.0.0.0";
        rpc-port = 9091;
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1,192.168.1.*,100.*.*.*";
        rpc-host-whitelist-enabled = true;
        rpc-host-whitelist = "server,server.lan,server.lan:9091,localhost,localhost:9091";
        rpc-authentication-required = false;

        # Network
        peer-port = 51413;
        port-forwarding-enabled = true;

        # Seeding behavior
        ratio-limit-enabled = true;
        ratio-limit = 2.0;
        idle-seeding-limit-enabled = true;
        idle-seeding-limit = 30; # minutes
      };
    };

    # Media serving
    plex = {
      enable = true;
      openFirewall = true; # 32400
      group = "media";
    };
  };

  nixpkgs.config.allowUnfree = true; # Required for Plex

  # Open firewall ports for Transmission
  networking.firewall.allowedTCPPorts = [
    9091 # RPC/Web interface
    51413 # BitTorrent peer connections
  ];
  networking.firewall.allowedUDPPorts = [
    51413 # BitTorrent peer connections (DHT, etc.)
  ];
}

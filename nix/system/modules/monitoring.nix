# NixOS module for setting system montoring with Netdata
{pkgs, ...}: {
  services.netdata = {
    enable = true;
    package = pkgs.netdata.override {withCloudUi = true;};

    config = {
      global = {
        # Performance settings
        "update every" = "1"; # 1 second collection interval
        "history" = "3996"; # ~1 hour in RAM before flushing to disk

        # Logging
        "debug log" = "none";
        "access log" = "none";
        "error log" = "syslog";
      };

      # Database configuration (correct section)
      db = {
        "mode" = "dbengine";
        "storage tiers" = "3";
        "dbengine page cache size" = "32"; # MB - ultra-conservative for tight RAM
        "dbengine tier 0 retention size" = "75GiB"; # 2+ weeks for freeze debugging
        "dbengine tier 0 retention time" = "14d"; # 14 days for troubleshooting
      };

      web = {
        "bind to" = "127.0.0.1"; # Only bind to localhost
        "default port" = "19999"; # Explicit port setting
        "allow connections from" = "localhost 192.168.*"; # Allow LAN access
        "allow dashboard from" = "localhost 192.168.*";
        "allow badges from" = "*";
        "allow streaming from" = "localhost 192.168.*";
      };

      # Disable AI/ML features
      ml = {
        "enabled" = "no";
      };

      # Health monitoring without notifications
      health = {
        "enabled" = "yes";
        "health log history" = "432000"; # Keep health logs for 5 days
        "in memory max health log entries" = "1000";
      };
    };

    # Disable analytics and telemetry
    enableAnalyticsReporting = false;

    # Enable Python plugins for extended monitoring
    python = {
      enable = true;
      recommendedPythonPackages = false; # Keep it minimal for now
    };
  };

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [19999];

  # Nginx reverse proxy for clean access
  services.nginx = {
    enable = true;

    virtualHosts."netdata.server.lan" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:19999";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          # Optimize for real-time data
          proxy_buffering off;
          proxy_cache off;
          proxy_read_timeout 300s;
        '';
      };
    };
  };
}

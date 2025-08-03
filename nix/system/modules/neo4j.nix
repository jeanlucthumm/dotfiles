{
  config,
  pkgs,
  ...
}: {
  services.neo4j = {
    enable = true;

    # Custom data directory
    directories.home = "/srv/backups/neo4j";

    # Network configuration - listen on all interfaces for VPN access
    defaultListenAddress = "0.0.0.0";

    # HTTP connector - web interface access
    http = {
      enable = true;
    };

    # Bolt connector - for database drivers/applications
    bolt = {
      enable = true;
      tlsLevel = "DISABLED"; # No SSL/TLS needed for VPN
    };

    # HTTPS not needed for VPN setup
    https.enable = false;

    # Basic configuration
    extraServerConfig = ''
      # Security settings
      dbms.security.auth_enabled=true

      # Memory settings (conservative defaults)
      server.memory.heap.max_size=2G
      server.memory.pagecache.size=1G

      # Logging
      dbms.logs.debug.level=INFO

      # Transaction log settings
      dbms.tx_log.rotation.retention_policy=100M size
    '';
  };

  # Ensure the data directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /srv/backups/neo4j 0755 neo4j neo4j -"
  ];

  networking.firewall.allowedTCPPorts = [7474 7687]; # Neo4j ports
}


# Neo4j Graph Database Module
#
# This module provides a basic Neo4j configuration suitable for most use cases.
# 
# REQUIRED: Consumers must configure:
#   - services.neo4j.directories.home = "/path/to/data/directory";
#   - Appropriate systemd.tmpfiles.rules for the data directory
#
# OPTIONAL: Consumers may want to configure:
#   - Memory settings via extraServerConfig
#   - Custom firewall rules
{
  config,
  pkgs,
  ...
}: {
  services.neo4j = {
    enable = true;

    # Network configuration - listen on all interfaces for VPN access
    defaultListenAddress = "0.0.0.0";

    # HTTP connector - web interface access
    http = {
      enable = true;
    };

    # Bolt connector - for database drivers/applications
    bolt = {
      enable = true;
      tlsLevel = "DISABLED";
    };

    # HTTPS not needed for most setups
    https.enable = false;

    # Basic configuration
    extraServerConfig = ''
      # Security settings
      dbms.security.auth_enabled=true

      # Logging
      dbms.logs.debug.level=INFO

      # Transaction log settings
      dbms.tx_log.rotation.retention_policy=100M size
    '';
  };

  networking.firewall.allowedTCPPorts = [7474 7687]; # Neo4j ports

  # Set initial password before Neo4j starts for the first time
  systemd.services.neo4j-set-initial-password = {
    description = "Set Neo4j initial password";
    wantedBy = ["multi-user.target"];
    before = ["neo4j.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "neo4j";
      Group = "neo4j";
    };
    script = ''
      # Check if password has already been set by looking for our marker file
      if [ ! -f "${config.services.neo4j.directories.home}/.password-initialized" ]; then
        echo "Setting initial Neo4j password..."
        PASSWORD=$(cat ${config.age.secrets.jeanluc-neo4j.path})
        
        # Set environment variables for neo4j-admin
        export NEO4J_HOME="${config.services.neo4j.directories.home}"
        
        if ${config.services.neo4j.package}/bin/neo4j-admin dbms set-initial-password "$PASSWORD"; then
          echo "Password set successfully"
          # Create marker file to prevent running again
          touch "${config.services.neo4j.directories.home}/.password-initialized"
        else
          echo "Failed to set password, may already be initialized"
        fi
      else
        echo "Neo4j password already initialized, skipping"
      fi
    '';
  };
}


{
  flake.modules.nixos.homeServer = {config, ...}: {
    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        volumes = ["/var/lib/home-assistant:/config"];
        environment.TZ = "America/Los_Angeles";
        image = "ghcr.io/home-assistant/home-assistant:2025.9.1";
        extraOptions = [
          "--network=host"
          "--device=/dev/ttyUSB0:/dev/ttyUSB0"
          "--privileged"
        ];
      };
    };

    # Ensure Home Assistant directory exists with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/home-assistant 0755 root root -"
    ];

    # TODO this has never worked
    # Reverse proxy entry
    services.nginx.virtualHosts.${config.networking.hostName}.locations."/hass/" = {
      proxyPass = "http://127.0.0.1:8123";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Important: Strip the /hass/ prefix
        rewrite ^/hass/(.*)$ /$1 break;
      '';
    };

    # Open Home Assistant port
    networking.firewall.allowedTCPPorts = [8123];
  };
}

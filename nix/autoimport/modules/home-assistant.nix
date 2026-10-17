{
  flake.modules.nixos.homeServer = {config, ...}: {
    # Z-Wave S0/S2 network keys. Root-owned 0400 is fine: the zwave-js unit
    # pulls this in via LoadCredential, which systemd reads as root.
    age.secrets.zwave-js-keys.file = ./secrets/_age/zwave-js-keys.age;

    # Z-Wave JS server for HA's Z-Wave integration (ws://localhost:3000).
    # HA runs as a plain container, so there's no Supervisor add-on for this.
    # Port stays closed in the firewall: the websocket is unauthenticated and
    # HA reaches it over host networking.
    services.zwave-js = {
      enable = true;
      # by-id so it can't swap with the Zigbee dongle across reboots.
      serialPort = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
      secretsConfigFile = config.age.secrets.zwave-js-keys.path;
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        volumes = ["/var/lib/home-assistant:/config"];
        environment.TZ = "America/Los_Angeles";
        image = "ghcr.io/home-assistant/home-assistant:2026.10.1";
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

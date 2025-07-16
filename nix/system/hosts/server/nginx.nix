{...}: {
  services.nginx = {
    enable = true;
    virtualHosts."server" = {
      serverAliases = ["server.lan"];
      locations."/hass/" = {
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
    };
  };

  networking.firewall.allowedTCPPorts = [80];
}

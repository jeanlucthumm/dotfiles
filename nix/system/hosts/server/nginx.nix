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
      locations."/transmission/" = {
        proxyPass = "http://127.0.0.1:9091";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          # Pass through Transmission session headers for CSRF protection
          proxy_pass_header X-Transmission-Session-Id;
          proxy_set_header X-Requested-With XMLHttpRequest;

          # Handle the transmission web interface paths properly
          proxy_redirect off;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80];
}

# Reverse proxy for the Syncthing GUI; the daemon is `jl.syncthing` in Home Manager.
{
  services.nginx.virtualHosts."server".locations."/syncthing/" = {
    proxyPass = "http://127.0.0.1:8384/";
    proxyWebsockets = true;
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';
  };
}

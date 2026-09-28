# nginx reverse proxy on server. Other modules hang `locations` off the one
# virtualHost. tailscaled fronts it with HTTPS on the tailnet: `tailscale
# serve` listens on 443 on the tailnet address only, terminates TLS with a
# Let's Encrypt cert for the node's MagicDNS name (Tailscale answers the ACME
# DNS challenge; requires MagicDNS + HTTPS certs enabled in the admin
# console), and proxies to nginx on localhost. Nothing is exposed off the
# tailnet.
{
  flake.modules.nixos.homeServer = {
    config,
    lib,
    ...
  }: {
    services.nginx = let
      host = config.networking.hostName;
    in {
      enable = true;
      # Other modules set `locations` on this
      virtualHosts.${host} = {
        serverAliases = ["${host}.lan"];
        # Requests via tailscale serve arrive with the ts.net name as Host.
        default = true;
      };
    };
    networking.firewall.allowedTCPPorts = [80];

    # `serve --bg` persists in tailscaled's state, so this is belt and braces:
    # the declaration lives here and is re-applied on rebuild. `reset` first
    # so a changed port or target does not leave the old entry behind; it
    # clears every serve/funnel entry on the node, so this unit must stay the
    # sole owner of serve config. The nixpkgs `services.tailscale.serve`
    # option is not this: it configures Tailscale Services (svc: virtual IPs),
    # whose hosts must be tagged nodes.
    systemd.services.tailscale-serve-nginx = {
      description = "Front nginx with HTTPS on the tailnet via tailscale serve";
      after = ["tailscaled.service" "nginx.service"];
      wants = ["tailscaled.service"];
      wantedBy = ["multi-user.target"];
      path = [config.services.tailscale.package];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # The CLI needs tailscaled's socket; retry until it is up.
        Restart = "on-failure";
        RestartSec = 5;
      };
      script = ''
        tailscale serve reset
        tailscale serve --bg --https=443 http://127.0.0.1:80
      '';
    };
  };
}

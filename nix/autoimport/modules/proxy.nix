{
  flake.modules.nixos.homeServer = {config, ...}: {
    services.nginx = let
      host = config.networking.hostName;
    in {
      enable = true;
      # Other modules set `locations` on this
      virtualHosts.${host}.serverAliases = ["${host}.lan"];
    };
    networking.firewall.allowedTCPPorts = [80];
  };
}

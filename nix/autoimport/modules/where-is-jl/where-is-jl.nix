# `where-is-jl`: where Jean-Luc's phone is, from Home Assistant, so the hubs
# can answer "where is he". Run with --help for the output.
#
# The token belongs to the HA user `where-is-jl`, which sits in a custom
# group whose policy lets it read person.jean_luc, zone.home and
# sensor.jean_lucs_iphone_geocoded_location, and nothing else: no other
# entity, no service calls. Sakina's phone is in the same HA, and agents that
# read email can run anything `jeanluc` can, so the token's reach is the
# whole boundary. A root-owned wrapper wouldn't add one: `jeanluc` has
# passwordless sudo.
#
# HA has no UI for custom groups. The group lives in
# /var/lib/home-assistant/.storage/auth (edit it with HA stopped), as
#   {"id": "where-is-jl", "name": "where-is-jl", "policy": {"entities":
#     {"entity_ids": {"person.jean_luc": {"read": true}, ...}}}}
# with the user's group_ids set to ["where-is-jl"]. Editing the user in the
# HA UI can put it back in a system group, so check it after.
_: {
  flake.modules.nixos.homeServer = {config, ...}: let
    tokenFile = config.age.secrets.ha-location-token.path;
  in {
    age.secrets.ha-location-token = {
      file = ../secrets/_age/ha-location-token.age;
      owner = "jeanluc";
    };

    home-manager.users.jeanluc = {pkgs, ...}: {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "where-is-jl";
          runtimeInputs = with pkgs; [coreutils curl jq];
          text = "token_file=${tokenFile}\n" + builtins.readFile ./where-is-jl.sh;
        })
      ];
    };
  };
}

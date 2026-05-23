{config, ...}: let
  user = "jeanluc";
in {
  flake.modules.darwin.base = {
    users.users.${user} = {
      name = user;
      home = "/Users/${user}";
    };
  };
}

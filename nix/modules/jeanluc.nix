{config, ...}: let
  user = "jeanluc";
in {
  flake.modules.darwin.${user} = {
    users.users.${user} = {
      name = user;
      home = "/Users/${user}";
    };
  };
}

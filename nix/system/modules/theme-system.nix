{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.theme.enable (
    let
      t = config.theme.name;
      d = config.theme.darkMode;
    in {
      programs.vivid = {
        enable = true;
        theme =
          if t == "gruvbox"
          then
            if d
            then "gruvbox-dark-soft"
            else "gruvbox-light-soft"
          else if t == "zenbones"
          then "zenburn"
          else if t == "snazzy"
          then "snazzy"
          else throw "unknown theme ${t}";
      };
    }
  );
}

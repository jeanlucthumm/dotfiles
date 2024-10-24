{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../theme.nix
  ];

  # System-wide themeing
  stylix = let
    t = config.theme.name;
    d = config.theme.darkMode;
  in {
    enable = true;
    image =
      if t == "gruvbox"
      then
        # Always dark wallpaper since we want contrast
        ../wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
      else throw "unknown theme ${t}";
    polarity =
      if d
      then "dark"
      else "light";
    base16Scheme =
      if t == "gruvbox"
      then
        if d
        then "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-soft.yaml"
        else "${pkgs.base16-schemes}/share/themes/gruvbox-material-light-soft.yaml"
      else throw "unknown theme ${t}";
    fonts = let
      fontPkg = pkgs.nerdfonts.override {
        # Narrow down since all of nerdfonts is a lot.
        fonts = ["JetBrainsMono" "FiraCode"];
      };
    in {
      monospace = {
        package = fontPkg;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sizes = {
        applications = 10;
      };
    };
  };
}

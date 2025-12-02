{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  fontType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
      };
      size = mkOption {
        type = types.int;
      };
      package = mkOption {
        type = types.package;
      };
    };
  };
in {
  options.theme = {
    enable = mkEnableOption "theme";
    name = mkOption {
      description = "Name of the theme to use (gruvbox)";
      type = types.str;
    };
    darkMode = mkOption {
      description = "Whether to enable dark mode (T) or light mode (F).";
      type = types.bool;
      default = false;
    };
    variant = mkOption {
      description = "Optional variant of a theme.";
      type = types.str;
      default = "";
    };
    fontCoding = mkOption {
      description = "Font used for coding.";
      type = fontType;
      default = {
        name = "JetBrainsMono Nerd Font Mono";
        size = 12;
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
    };
  };

  # Delegate to Stylix for majority of themeing.
  config = lib.mkIf config.theme.enable (
    let
      t = config.theme.name;
      d = config.theme.darkMode;
    in {
      stylix = {
        enable = true;
        image =
          if t == "gruvbox"
          then
            # Always dark wallpaper since we want contrast
            ../../wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
          else if t == "zenbones"
          then
            ../../wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
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
          else if t == "zenbones"
          then
            if d
            then "${pkgs.base16-schemes}/share/themes/zenbones.yaml"
            else ../../themes/zenbones-light.yaml
          else throw "unknown theme ${t}";
        fonts = {
          monospace = {
            package = config.theme.fontCoding.package;
            name = config.theme.fontCoding.name;
          };
          sizes = {
            applications = 10;
            terminal = config.theme.fontCoding.size;
          };
        };
      };
    }
  );
}

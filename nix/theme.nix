{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.theme;
  fontType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
      };
      size = mkOption {
        type = types.int;
      };
      # TODO: package providing the font
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
    };
  };
}

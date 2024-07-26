{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.theme;
in {
  options.theme = {
    enable = mkEnableOption "theme";
    name = mkOption {
      type = types.str;
      default = "gruvbox";
    };
    variant = mkOption {
      type = types.str;
      default = "dark";
    };
  };

  config.stylix = mkIf cfg.enable (
    if cfg.name == "gruvbox"
    then {
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-${cfg.variant}-soft.yaml";
      image =
        if cfg.variant == "light"
        then ./wallpapers/gruvbox-light-rainbow.png
        else ./wallpapers/gruvbox-dark-rainbow.png;
    }
    else {}
  );
}

{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  # Shorter name to access final settings a
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.theme;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
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

  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module
  # by setting "services.hello.enable = true;".
  config.stylix = mkIf cfg.enable (
    if cfg.name == "gruvbox"
    then {
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-${cfg.variant}-soft.yaml";
      image =
        if cfg.variant == "light"
        then ./wallpaper.jpg
        else ./gruvbox-dark-rainbow.png;
    }
    else {}
  );
}

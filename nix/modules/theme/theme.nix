# Themeing
{
  config,
  inputs,
  lib,
  ...
}: let
  # Stylix settings to apply to multiple module trees
  # Supported themes (TODO: write out when not too lazy):
  #
  # Rose Pine
  # =========
  # theme = {
  #   name = "rose-pine";
  #   variant = "moon";
  # };
  stylixImpl = p: let
    t = p.config.theme.name;
    d = p.config.theme.darkMode;
    pkgs = p.pkgs;
  in {
    enable = true;
    image =
      if t == "gruvbox"
      then
        # Always dark wallpaper since we want contrast
        ./wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
      else if t == "zenbones"
      then ./wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
      else if t == "snazzy"
      then ./wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
      else if t == "rose-pine"
      then ./wallpapers/gruvbox/dark/great-wave-of-kanagawa-gruvbox.png
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
      else if t == "snazzy"
      then
        if d
        then "${pkgs.base16-schemes}/share/themes/snazzy.yaml"
        else ../../themes/snazzy-light.yaml
      else if t == "rose-pine"
      then
        if d
        then
          if p.config.theme.variant == "moon"
          then "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml"
          else "${pkgs.base16-schemes}/share/themes/rose-pine.yaml"
        else "${pkgs.base16-schemes}/share/themes/rose-pine-dawn.yaml"
      else throw "unknown theme ${t}";
    fonts = {
      monospace = {
        package = p.config.theme.fontCoding.package;
        name = p.config.theme.fontCoding.name;
      };
      sizes = {
        applications = 10;
        terminal = p.config.theme.fontCoding.size;
      };
    };
    homeManagerIntegration.followSystem = false;
    enableReleaseChecks = false;
  };
in {
  flake.modules.generic.theme = {
    lib,
    pkgs,
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
    };

  flake.modules.nixos.theme = nixosParams: {
    imports = [
      inputs.stylix.nixosModules.stylix
      config.flake.modules.generic.theme
    ];

    stylix = stylixImpl nixosParams;
  };

  flake.modules.darwin.theme = darwinParams: {
    imports = [
      inputs.stylix.darwinModules.stylix
      config.flake.modules.generic.theme
    ];

    stylix = stylixImpl darwinParams;
  };
}

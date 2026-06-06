# Themeing
fp: {
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

      config = {
        stylix = let
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
              else ./themes/zenbones-light.yaml
            else if t == "snazzy"
            then
              if d
              then "${pkgs.base16-schemes}/share/themes/snazzy.yaml"
              else ./themes/snazzy-light.yaml
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
      };
    };

  flake.modules.nixos.theme = {
    config,
    lib,
    ...
  }: let
    t = config.theme.name;
    d = config.theme.darkMode;
  in {
    imports = [
      fp.inputs.stylix.nixosModules.stylix
      fp.config.flake.modules.generic.theme
    ];

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
        then
          if d
          then "snazzy"
          else ./themes/vivid/snazzy-light.yml
        else throw "unknown theme ${t}";
    };

    home-manager.sharedModules = [
      fp.config.flake.modules.homeManager.theme
      {
        theme = config.theme;
      }
    ];
  };

  flake.modules.darwin.theme = {config, ...}: {
    imports = [
      fp.inputs.stylix.darwinModules.stylix
      fp.config.flake.modules.generic.theme
    ];

    home-manager.sharedModules = [
      fp.config.flake.modules.homeManager.theme
      {
        theme = config.theme;
      }
    ];
  };
}

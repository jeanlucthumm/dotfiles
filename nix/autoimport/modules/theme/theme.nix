# Themeing
fp: {
  flake.modules.generic.theme = {
    config,
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
          description = ''
            Default polarity: dark (T) or light (F). Build-time targets (stylix,
            LS_COLORS, taskwarrior) use it, and live targets (kitty, nvim) fall
            back to it when the OS reports no preference. Kitty and nvim follow
            the OS appearance live; flip it with `theme-toggle`.
          '';
          type = types.bool;
          default = false;
        };
        variant = mkOption {
          description = "Optional variant of a theme.";
          type = types.str;
          default = "";
        };
        base16Schemes = mkOption {
          description = "base16 scheme per polarity, derived from name/variant.";
          internal = true;
          type = types.attrsOf types.path;
          default = let
            t = config.theme.name;
            s = name: "${pkgs.base16-schemes}/share/themes/${name}.yaml";
          in
            if t == "gruvbox"
            then {
              dark = s "gruvbox-material-dark-soft";
              light = s "gruvbox-material-light-soft";
            }
            else if t == "zenbones"
            then {
              dark = s "zenbones";
              light = ./themes/zenbones-light.yaml;
            }
            else if t == "snazzy"
            then {
              dark = s "snazzy";
              light = ./themes/snazzy-light.yaml;
            }
            else if t == "rose-pine"
            then {
              dark = s (
                if config.theme.variant == "moon"
                then "rose-pine-moon"
                else "rose-pine"
              );
              light = s "rose-pine-dawn";
            }
            else throw "unknown theme ${t}";
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

  flake.modules.generic.stylixNonHm = {
    config,
    lib,
    pkgs,
    ...
  }: {
    stylix = let
      t = config.theme.name;
      d = config.theme.darkMode;
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
        if d
        then config.theme.base16Schemes.dark
        else config.theme.base16Schemes.light;
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
      enableReleaseChecks = false;

      # IMPORTANT
      # Disable overalys because otherwise stylix allows modules to do `nixpkgs.overlays` which
      # is a no-no with our read-only nixpkgs. Unfortunately this means we don't get themeing
      # for a few things. So far only gtksourceview, nixos-icons, and gdm stuff, none of which
      # is used.
      overlays.enable = false;
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
      fp.config.flake.modules.generic.stylixNonHm
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
      fp.config.flake.modules.generic.theme
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
      fp.config.flake.modules.generic.stylixNonHm
    ];

    home-manager.sharedModules = [
      fp.config.flake.modules.generic.theme
      fp.config.flake.modules.homeManager.theme
      {
        theme = config.theme;
      }
    ];
  };
}

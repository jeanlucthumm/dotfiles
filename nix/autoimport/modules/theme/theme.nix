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
            Default polarity: dark (T) or light (F). Used where the OS appearance
            isn't followed live, or when the OS reports no preference. Flip the
            live mode with `theme-toggle`.
          '';
          type = types.bool;
          default = false;
        };
        variant = mkOption {
          description = "Optional variant of a theme.";
          type = types.str;
          default = "";
        };
        modes = mkOption {
          description = "Per-polarity assets (base16 scheme, kitty colors, vivid theme), derived from name/variant.";
          internal = true;
          type = types.attrsOf (types.attrsOf types.anything);
          default = let
            base16 = name: "${pkgs.base16-schemes}/share/themes/${name}.yaml";
            kittyUpstream = name: "${pkgs.kitty-themes}/share/kitty-themes/themes/${name}.conf";
            # Custom files where upstream lacks a variant or real bright colors.
            kittyCustom = name: ./themes/kitty + "/${name}.conf";
            moon = config.theme.variant == "moon";
          in
            {
              gruvbox = {
                dark = {
                  base16 = base16 "gruvbox-material-dark-soft";
                  kitty = kittyUpstream "GruvboxMaterialDarkSoft";
                  vivid = "gruvbox-dark-soft";
                };
                light = {
                  base16 = base16 "gruvbox-material-light-soft";
                  kitty = kittyUpstream "GruvboxMaterialLightSoft";
                  vivid = "gruvbox-light-soft";
                };
              };
              zenbones = {
                dark = {
                  base16 = base16 "zenbones";
                  kitty = kittyUpstream "zenbones_dark";
                  vivid = "zenburn";
                };
                light = {
                  base16 = ./themes/zenbones-light.yaml;
                  kitty = kittyUpstream "zenbones_light";
                  vivid = "zenburn";
                };
              };
              snazzy = {
                dark = {
                  base16 = base16 "snazzy";
                  kitty = kittyCustom "snazzy_dark";
                  vivid = "snazzy";
                };
                light = {
                  base16 = ./themes/snazzy-light.yaml;
                  kitty = kittyCustom "snazzy_light";
                  vivid = "${./themes/vivid/snazzy-light.yml}";
                };
              };
              rose-pine = {
                dark = {
                  base16 = base16 (
                    if moon
                    then "rose-pine-moon"
                    else "rose-pine"
                  );
                  kitty = kittyCustom (
                    if moon
                    then "rose-pine_moon"
                    else "rose-pine_dark"
                  );
                  vivid =
                    if moon
                    then "rose-pine-moon"
                    else "rose-pine";
                };
                light = {
                  base16 = base16 "rose-pine-dawn";
                  kitty = kittyCustom "rose-pine_light";
                  vivid = "rose-pine-dawn";
                };
              };
            }
            .${
              config.theme.name
            }
            or (throw "unknown theme ${config.theme.name}");
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
      polarity =
        if config.theme.darkMode
        then "dark"
        else "light";
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
      inherit polarity;
      base16Scheme = config.theme.modes.${polarity}.base16;
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

  flake.modules.nixos.theme = {config, ...}: {
    imports = [
      fp.inputs.stylix.nixosModules.stylix
      fp.config.flake.modules.generic.theme
      fp.config.flake.modules.generic.stylixNonHm
    ];

    programs.vivid = {
      enable = true;
      theme = config.theme.modes.${config.stylix.polarity}.vivid;
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

# Home-manager theme integration (additional configs not done through stylix).
#
# Reads theme via `osConfig.theme.*` rather than declaring the theme option
# in HM. Single source of truth at the system level; the `osConfig.` prefix
# makes cross-context access explicit. Hosts must import this slot
# explicitly (it's not in `base`) so untheme'd hosts don't drag it in.
fp @ {jlib, ...}: {
  flake.modules.homeManager.theme = {
    osConfig ? throw "Theme not supported in standalone HM",
    pkgs,
    config,
    lib,
    ...
  }: let
    theme = osConfig.theme;
    n = theme.name;
    themeDarkMode =
      if theme.darkMode
      then "dark"
      else "light";
  in
    jlib.mkHomeManager {
      generic = {
        # NB: don't import stylix.homeModules.stylix here — the system stylix
        # module auto-imports it via homeManagerIntegration (default true).
        # Importing it manually causes read-only options like `stylix.base16`
        # to be set twice.
        stylix.targets = {
          qutebrowser.enable = false;
          # Use custom kitty themes instead of Stylix's base16 mapping
          kitty.enable = n != "zenbones" && n != "snazzy" && n != "rose-pine";
        };

        # Custom kitty themes (have proper bright color variants)
        # Also need to set font manually since we disabled Stylix's kitty target
        programs.kitty = lib.mkIf (n == "zenbones" || n == "snazzy" || n == "rose-pine") {
          font = {
            name = theme.fontCoding.name;
            size = theme.fontCoding.size;
            package = theme.fontCoding.package;
          };
          extraConfig = let
            kittyThemeFile =
              if n == "rose-pine" && theme.variant == "moon"
              then "rose-pine_moon.conf"
              else "${n}_${themeDarkMode}.conf";
          in ''
            include ${./themes/kitty}/${kittyThemeFile}
          '';
        };

        programs.taskwarrior = {
          colorTheme =
            if theme.darkMode
            then ./taskwarrior-themes/dark-256.theme
            else ./taskwarrior-themes/light-256.theme;
        };

        # Neovim theme - uses Stylix colors for base16 themes
        home.file = {
          "${config.xdg.configHome}/nvim/lua/theme.lua".text = with config.lib.stylix.colors; let
            # For base16 themes, we inject the colors directly
            base16Setup = ''
              require('base16-colorscheme').setup({
                base00 = '#${base00}', base01 = '#${base01}', base02 = '#${base02}', base03 = '#${base03}',
                base04 = '#${base04}', base05 = '#${base05}', base06 = '#${base06}', base07 = '#${base07}',
                base08 = '#${base08}', base09 = '#${base09}', base0A = '#${base0A}', base0B = '#${base0B}',
                base0C = '#${base0C}', base0D = '#${base0D}', base0E = '#${base0E}', base0F = '#${base0F}',
              })
            '';
            rosePineVariant =
              if theme.darkMode
              then
                (
                  if theme.variant == "moon"
                  then "moon"
                  else "main"
                )
              else "dawn";
            rosePineSetup = ''
              require'rose-pine'.setup {
                variant = '${rosePineVariant}',
                dark_variant = '${
                if theme.variant == "moon"
                then "moon"
                else "main"
              }',
                disable_italics = true,
              }
              lualine_theme = 'rose-pine'
              vim.cmd('colorscheme rose-pine')
            '';
            themeSetup =
              if n == "gruvbox"
              then "GruvboxTheme('${themeDarkMode}')"
              else if n == "zenbones"
              then "ZenbonesTheme('${themeDarkMode}')"
              else if n == "snazzy"
              then base16Setup
              else if n == "rose-pine"
              then rosePineSetup
              else throw "Unsupported nvim theme: ${n}";
          in ''
            local M = {}

            function M.setup()
              vim.o.background = '${themeDarkMode}'
              ${themeSetup}
              vim.o.guifont = "${theme.fontCoding.name}:h${toString theme.fontCoding.size}"
            end

            return M
          '';
        };

        # Nushell doesn't have vivid integration yet
        programs.nushell.environmentVariables = let
          vividTheme =
            if n == "gruvbox"
            then "gruvbox-${themeDarkMode}-soft"
            else if n == "zenbones"
            then "zenburn"
            else if n == "snazzy"
            then
              if theme.darkMode
              then "snazzy"
              else "${./themes/vivid/snazzy-light.yml}"
            else if n == "rose-pine"
            then
              if theme.darkMode
              then
                if theme.variant == "moon"
                then "rose-pine-moon"
                else "rose-pine"
              else "rose-pine-dawn"
            else throw "Unsupported nushell theme: ${n}";
        in {
          LS_COLORS = lib.hm.nushell.mkNushellInline ''
            ${pkgs.vivid}/bin/vivid generate ${vividTheme}
          '';
        };
      };

      nixos = {
        stylix.targets = {
          wofi.enable = false;
          hyprlock.enable = false;
          zen-browser.enable = false;
        };

        programs.wofi.style = with config.lib.stylix.colors; ''
          window {
            border: solid 2px;
          }

          #input {
            padding: 10px;
            margin: 20px;
            padding-left: 10px;
            padding-right: 10px;
            border-radius: 20px;
          }

          #input:focus {
            border: none;
            outline: none;
          }

          #inner-box {
            margin: 10px;
            margin-top: 0px;
            border-radius: 20px;
          }

          #outer-box {
            border: none;
          }

          #scroll {
            margin: 0px 10px 20px 10px;
          }

          #text:selected {
            color: #fff;
          }

          #img {
            background: transparent;
            margin-right: 10px;
            margin-left: 5px;
          }

          #entry {
            padding: 10px;
            border: none;
            border-radius: 20px;
          }

          #entry:selected {
            outline: none;
            border: none;
          }

          #entry:nth-child(odd) {
            background-color: ${base00};
          }
          #entry:nth-child(even) {
            background-color: ${base01};
          }
          #entry:selected {
            background-color: ${base02};
          }
          #input {
            background-color: ${base01};
            color: ${base04};
            border-color: ${base02};
          }
          #input:focus {
            border-color: ${base0A};
          }
        '';
      };
    };
}

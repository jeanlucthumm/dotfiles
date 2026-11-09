# Home-manager theme integration (additional configs not done through stylix).
#
# Reads theme via `osConfig.theme.*` rather than declaring the theme option
# in HM. Single source of truth at the system level; the `osConfig.` prefix
# makes cross-context access explicit. Hosts must import this slot
# explicitly (it's not in `base`) so untheme'd hosts don't drag it in.
fp @ {jlib, ...}: {
  flake.modules.homeManager.theme = jlib.mkHomeManager {
    generic = {
      config,
      lib,
      pkgs,
      osConfig ? {},
      ...
    }: let
      theme = osConfig.theme;
      n = theme.name;
      themeDarkMode =
        if theme.darkMode
        then "dark"
        else "light";

      kittyThemes = let
        custom = ./themes/kitty;
        upstream = "${pkgs.kitty-themes}/share/kitty-themes/themes";
      in
        if n == "gruvbox"
        then {
          dark = "${upstream}/GruvboxMaterialDarkSoft.conf";
          light = "${upstream}/GruvboxMaterialLightSoft.conf";
        }
        else if n == "rose-pine"
        then {
          dark = "${custom}/rose-pine_${
            if theme.variant == "moon"
            then "moon"
            else "dark"
          }.conf";
          light = "${custom}/rose-pine_light.conf";
        }
        else if n == "zenbones" || n == "snazzy"
        then {
          dark = "${custom}/${n}_dark.conf";
          light = "${custom}/${n}_light.conf";
        }
        else throw "Unsupported kitty theme: ${n}";

      # Flips the OS appearance; kitty and nvim follow it live.
      theme-toggle = pkgs.writeShellApplication {
        name = "theme-toggle";
        runtimeInputs = lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.dconf;
        text =
          if pkgs.stdenv.hostPlatform.isDarwin
          then ''
            case "''${1:-toggle}" in
              dark) to=true ;;
              light) to=false ;;
              toggle) to="not dark mode" ;;
              *) echo "usage: theme-toggle [dark|light]" >&2; exit 2 ;;
            esac
            /usr/bin/osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $to"
          ''
          else ''
            # Read by the xdg-desktop-portal Settings backend, which kitty queries.
            key=/org/gnome/desktop/interface/color-scheme
            case "''${1:-toggle}" in
              dark) to=prefer-dark ;;
              light) to=prefer-light ;;
              toggle)
                case "$(dconf read "$key")" in
                  "'prefer-dark'") to=prefer-light ;;
                  "'prefer-light'") to=prefer-dark ;;
                  # 'default' shows the build-time polarity, so flip away from it.
                  *) to=${
              if theme.darkMode
              then "prefer-light"
              else "prefer-dark"
            } ;;
                esac
                ;;
              *) echo "usage: theme-toggle [dark|light]" >&2; exit 2 ;;
            esac
            dconf write "$key" "'$to'"
          '';
      };
    in {
      home.packages = [theme-toggle];

      # NB: don't import stylix.homeModules.stylix here — the system stylix
      # module auto-imports it via homeManagerIntegration (default true).
      # Importing it manually causes read-only options like `stylix.base16`
      # to be set twice.
      stylix.targets = {
        qutebrowser.enable = false;
        # Unused, and stylix sets the renamed `programs.rofi.font` (eval warning).
        rofi.enable = false;
        # Stylix maps one base16 scheme (no real bright colors, one polarity).
        # Kitty gets light + dark theme files below instead.
        kitty.enable = false;
      };

      programs.kitty.font = {
        inherit (theme.fontCoding) name size package;
      };

      # Kitty swaps between these live whenever the OS appearance changes.
      # no-preference covers GNOME-style "default" and a missing portal.
      xdg.configFile = {
        "kitty/dark-theme.auto.conf".source = kittyThemes.dark;
        "kitty/light-theme.auto.conf".source = kittyThemes.light;
        "kitty/no-preference-theme.auto.conf".source = kittyThemes.${themeDarkMode};
      };

      programs.taskwarrior = {
        colorTheme =
          if theme.darkMode
          then ./taskwarrior-themes/dark-256.theme
          else ./taskwarrior-themes/light-256.theme;
      };

      # Neovim theme. Every setup below follows 'background' instead of
      # hard-coding a polarity, so a live 'background' change re-themes.
      home.file = {
        "${config.xdg.configHome}/nvim/lua/theme.lua".text = let
          base16Palette = scheme: let
            c = config.stylix.base16.mkSchemeAttrs scheme;
            keys = map (i: "base0${i}") (lib.stringToCharacters "0123456789ABCDEF");
          in "{ ${lib.concatMapStringsSep ", " (k: "${k} = '#${c.${k}}'") keys} }";
          themeSetup =
            if n == "gruvbox"
            then "GruvboxTheme(vim.o.background)"
            else if n == "zenbones"
            then "ZenbonesTheme(vim.o.background)"
            else if n == "snazzy"
            then ''
              require('base16-colorscheme').setup(({
                dark = ${base16Palette theme.base16Schemes.dark},
                light = ${base16Palette theme.base16Schemes.light},
              })[vim.o.background])
            ''
            else if n == "rose-pine"
            then ''
              require'rose-pine'.setup {
                variant = 'auto',
                dark_variant = '${
                if theme.variant == "moon"
                then "moon"
                else "main"
              }',
                disable_italics = true,
              }
              vim.cmd('colorscheme rose-pine')
            ''
            else throw "Unsupported nvim theme: ${n}";
          lualineTheme =
            if n == "gruvbox" || n == "rose-pine"
            then n
            else "auto";
        in ''
          local M = {}

          M.lualine_theme = '${lualineTheme}'

          local function apply()
            ${themeSetup}
          end

          function M.setup()
            if vim.g.neovide then
              vim.g.neovide_theme = 'auto'
            elseif not vim.api.nvim_get_option_info2('background', {}).was_set then
              -- Terminal didn't report its background color: use the build default.
              vim.o.background = '${themeDarkMode}'
            end
            apply()
            -- The TUI updates 'background' live when kitty reports an OS
            -- light/dark switch (DEC mode 2031).
            vim.api.nvim_create_autocmd('OptionSet', {
              group = vim.api.nvim_create_augroup('nix_theme', {}),
              pattern = 'background',
              callback = apply,
            })
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

    nixos = {config, ...}: {
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

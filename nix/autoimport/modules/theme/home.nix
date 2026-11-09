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
      inherit (theme) modes;
      defaultMode =
        if theme.darkMode
        then "dark"
        else "light";
      oppositeMode =
        if theme.darkMode
        then "light"
        else "dark";

      # Read (nushell) and set (bash) the OS appearance.
      appearance =
        if pkgs.stdenv.hostPlatform.isDarwin
        then {
          detect = ''if ((^/usr/bin/defaults read -g AppleInterfaceStyle | complete).stdout | str trim) == "Dark" { "dark" } else { "light" }'';
          toggle = ''
            case "''${1:-toggle}" in
              dark) to=true ;;
              light) to=false ;;
              toggle) to="not dark mode" ;;
              *) echo "usage: theme-toggle [dark|light]" >&2; exit 2 ;;
            esac
            /usr/bin/osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $to"
          '';
        }
        else let
          # Exposed by the xdg-desktop-portal Settings backend, which kitty queries.
          # 'default' means no preference, i.e. defaultMode.
          key = "/org/gnome/desktop/interface/color-scheme";
          dconf = "${pkgs.dconf}/bin/dconf";
        in {
          detect = ''
            match ((^${dconf} read ${key} | complete).stdout | str trim) {
              "'prefer-dark'" => "dark"
              "'prefer-light'" => "light"
              _ => "${defaultMode}"
            }'';
          toggle = ''
            case "''${1:-toggle}" in
              dark | light) to=$1 ;;
              toggle)
                case "$(${dconf} read ${key})" in
                  "'prefer-dark'") to=light ;;
                  "'prefer-light'") to=dark ;;
                  *) to=${oppositeMode} ;;
                esac
                ;;
              *) echo "usage: theme-toggle [dark|light]" >&2; exit 2 ;;
            esac
            ${dconf} write ${key} "'prefer-$to'"
          '';
        };

      # Each setup follows 'background' and must not set it: nvim stops
      # updating 'background' from the terminal once a script sets it.
      nvimTheme = let
        base16Keys = map (i: "base0${i}") (lib.stringToCharacters "0123456789ABCDEF");
        base16Palettes = lib.generators.toLua {multiline = false;} (lib.mapAttrs (_: m:
          lib.getAttrs base16Keys (config.stylix.base16.mkSchemeAttrs m.base16).withHashtag)
        modes);
      in
        {
          gruvbox = {
            lualine = "gruvbox";
            setup = "vim.cmd('colorscheme gruvbox')";
          };
          zenbones = {
            lualine = "auto";
            setup = "vim.cmd('colorscheme zenbones')";
          };
          snazzy = {
            lualine = "auto";
            setup = "require('base16-colorscheme').setup((${base16Palettes})[vim.o.background])";
          };
          rose-pine = {
            lualine = "rose-pine";
            setup = ''
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
            '';
          };
        }
        .${
          theme.name
        }
        or (throw "Unsupported nvim theme: ${theme.name}");
    in {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "theme-toggle";
          text = appearance.toggle;
        })
      ];

      # NB: don't import stylix.homeModules.stylix here — the system stylix
      # module auto-imports it via homeManagerIntegration (default true).
      # Importing it manually causes read-only options like `stylix.base16`
      # to be set twice.
      stylix.targets = {
        qutebrowser.enable = false;
        # Unused, and stylix sets the renamed `programs.rofi.font` (eval warning).
        rofi.enable = false;
        # These map one polarity. Kitty and starship get light + dark below;
        # nushell's default color_config uses ANSI names, so it follows kitty.
        kitty.enable = false;
        starship.enable = false;
        nushell.enable = false;
      };

      # Stylix's kitty target is off, so set the font here.
      programs.kitty.font = theme.fontCoding;

      xdg.configFile = let
        starshipConfig = mode:
          (pkgs.formats.toml {}).generate "starship-${mode}.toml"
          (config.programs.starship.settings // {palette = mode;});
      in {
        # Kitty swaps between these itself whenever the OS appearance changes.
        "kitty/dark-theme.auto.conf".source = modes.dark.kitty;
        "kitty/light-theme.auto.conf".source = modes.light.kitty;
        "kitty/no-preference-theme.auto.conf".source = modes.${defaultMode}.kitty;
        # Picked per prompt by the nushell hook below.
        "starship/dark.toml".source = starshipConfig "dark";
        "starship/light.toml".source = starshipConfig "light";
      };

      # Palette names used by graphical/starship.nix.
      programs.starship.settings = {
        palette = defaultMode;
        palettes = lib.mapAttrs (_: m:
          with (config.stylix.base16.mkSchemeAttrs m.base16).withHashtag; {
            text = base00;
            text_alt = base07;
            c1 = base0D; # primary accent
            c2 = base04; # darker gray
            c3 = base03; # medium gray
            c4 = base02; # lighter gray
          })
        modes;
      };

      programs.taskwarrior = {
        colorTheme =
          if theme.darkMode
          then ./taskwarrior-themes/dark-256.theme
          else ./taskwarrior-themes/light-256.theme;
      };

      home.file."${config.xdg.configHome}/nvim/lua/theme.lua".text = ''
        local M = {}

        M.lualine_theme = '${nvimTheme.lualine}'

        local function apply()
          ${nvimTheme.setup}
        end

        function M.setup()
          if vim.g.neovide then
            vim.g.neovide_theme = 'auto'
          elseif not vim.api.nvim_get_option_info2('background', {}).was_set then
            -- Terminal didn't report its background color: use the default.
            vim.o.background = '${defaultMode}'
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

      # Point starship and LS_COLORS at the palette matching the OS appearance.
      # Detection costs ~6ms per prompt, cheap next to starship itself.
      programs.nushell.extraConfig = let
        lsColors = lib.mapAttrs (mode: m:
          pkgs.runCommand "ls-colors-${mode}" {} ''
            ${pkgs.vivid}/bin/vivid generate ${m.vivid} > $out
          '')
        modes;
      in ''
        $env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [] | append {||
          let mode = (${appearance.detect})
          if $mode != ($env.THEME_MODE? | default "") {
            $env.THEME_MODE = $mode
            $env.STARSHIP_CONFIG = $"${config.xdg.configHome}/starship/($mode).toml"
            $env.LS_COLORS = (open --raw ({dark: "${lsColors.dark}", light: "${lsColors.light}"} | get $mode) | str trim)
          }
        })
      '';
    };

    nixos = {config, ...}: {
      stylix.targets = {
        # Resets the color-scheme key on every activation, undoing theme-toggle.
        gnome.polarity.enable = false;
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

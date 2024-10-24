# Sets Home Assistant configs based on the top level theme.nix module.
# We can't put this directly into theme.nix because theme.nix is used both in
# the Home Assistant and host (NixOS/Darwin) config tree which have different
# available settings.
{config, ...}: let
  theme = config.theme;
  themeDarkMode =
    if theme.darkMode
    then "dark"
    else "light";
in {
  imports = [
    ../theme.nix
    ./ls-colors-hack.nix
  ];

  stylix.targets = {
    qutebrowser.enable = false;
    wofi.enable = false;
  };

  programs.nushell.environmentVariables = {
    BAT_THEME = ''${config.theme.name}-${themeDarkMode}'';
  };
  programs.fish.interactiveShellInit = ''
    set -g theme_nerd_fonts yes
    set -g theme_virtual_env_prompt_enabled no
    set -x BAT_THEME ${config.theme.name}-${themeDarkMode}
  '';

  programs.wofi.style = with config.lib.stylix.colors; ''
    window {
      border-radius: 20px;
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

  # Neovim theme
  home.file = {
    "${config.xdg.configHome}/nvim/lua/theme.lua".text = let
      n = theme.name;
      func =
        if n == "gruvbox"
        then "GruvboxTheme"
        else throw "Unsupported nvim theme: ${n}";
    in ''
      local M = {}

      function M.setup()
        ${func}('${themeDarkMode}')
        if vim.g.neovide then
          vim.o.guifont = "${theme.fontCoding.name}:h${toString theme.fontCoding.size}"
        end
      end

      return M
    '';
  };
}

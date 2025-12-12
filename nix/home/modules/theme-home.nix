# Additional home manager configs not done through stylix.
# Theme module is available due to home-manager.sharedModules despite
# it being defined as a system module.
{
  pkgs,
  config,
  lib,
  ...
}: let
  theme = config.theme;
  n = theme.name;
  themeDarkMode =
    if theme.darkMode
    then "dark"
    else "light";
in {
  imports = [
    ../programs/taskwarrior/theme.nix
  ];

  stylix.targets = {
    qutebrowser.enable = false;
    wofi.enable = false;
    hyprlock.enable = false;
    zen-browser.enable = false;
    # Use official zenbones kitty theme instead of Stylix's base16 mapping
    kitty.enable = n != "zenbones";
  };

  # Official zenbones kitty theme (has proper bright color variants)
  # Also need to set font manually since we disabled Stylix's kitty target
  programs.kitty = lib.mkIf (n == "zenbones") {
    font = {
      name = theme.fontCoding.name;
      size = theme.fontCoding.size;
      package = theme.fontCoding.package;
    };
    extraConfig = ''
      include ${../../themes/kitty/zenbones_${themeDarkMode}.conf}
    '';
  };

  programs.fish.interactiveShellInit = ''
    set -g theme_nerd_fonts yes
    set -g theme_virtual_env_prompt_enabled no
  '';

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

  # Neovim theme
  home.file = {
    "${config.xdg.configHome}/nvim/lua/theme.lua".text = let
      n = theme.name;
      func =
        if n == "gruvbox"
        then "GruvboxTheme"
        else if n == "zenbones"
        then "ZenbonesTheme"
        else throw "Unsupported nvim theme: ${n}";
    in ''
      local M = {}

      function M.setup()
        ${func}('${themeDarkMode}')
        vim.o.guifont = "${theme.fontCoding.name}:h${toString theme.fontCoding.size}"
      end

      return M
    '';
  };

  # Nushell doesn't have vivid integration yet
  programs.nushell.environmentVariables = let
    name =
      if n == "gruvbox"
      then "gruvbox-${themeDarkMode}-soft"
      else if n == "zenbones"
      then "zenburn"
      else throw "Unsupported nushell theme: ${n}";
  in {
    LS_COLORS = lib.hm.nushell.mkNushellInline ''
      ${pkgs.vivid}/bin/vivid generate ${name}
    '';
  };

}

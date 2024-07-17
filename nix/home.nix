{
  config,
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isArch = builtins.pathExists "/etc/arch-release";
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;
in {
  programs = {
    kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;
      shellIntegration.mode = "no-cursor";
      settings = {
        enable_audio_bell = true;
        window_padding_width = 8;
        allow_remote_control = false;
        repaint_delay = 5;
        input_delay = 1;
        cursor_shape = "blocK";
        macos_option_as_alt = true;
        scrollback_pager = "nvim -c 'set ft=sh' -";
        paste_actions = "quote-urls-at-prompt";
      };
    };
    taskwarrior = {
      enable = true;
      dataLocation = "${config.xdg.dataHome}/task";
      extraConfig = ''
        uda.blocks.type=string
        uda.blocks.label=Blocks
        news.version=2.6.0

        # Put contexts defined with `task context define` in this file
        include ${configDir}/task/context.config
        hooks.location=${configDir}/task/hooks
      '';
    };
    fish = {
      enable = true;
      plugins = with pkgs.fishPlugins; [
        {
          name = "fzf";
          src = fzf;
        }
        {
          name = "grc";
          src = grc;
        }
        {
          name = "agnoster";
          src = pkgs.fetchFromGitHub {
            owner = "jeanlucthumm";
            repo = "theme-agnoster";
            rev = "502ff4f34224c9aa90a8d0a3ad517940eaf4d4fd";
            sha256 = "12gc6mw5cb3pdqp8haqx9abgjw64v3960g0f0hgb122xa3z7qldm";
          };
        }
      ];
      shellAbbrs = {
        g = "git";
        t = "task";
        docker = "sudo docker";
        ga = "git add -A";
        gm = "git commit -m";
        ym = "yadm commit -m";
        gs = "git stat";
        gt = "git tree";
        gd = "git d";
        gda = "git add -A && git d";
        yda = "yadm add -u -p && yadm d";
        clear-nvim-swap = "rm -rf ~/.local/state/nvim/swap";
        ta = "task active";
        tr = "task ready";
        tdesc = "tprop description";
        day = "timew day";
        acc = "task end.after:today completed";
      };
      # Like shellAbbrs but doesn't auto expand when typing
      shellAliases = {
        vim = "nvim";
        cat = "bat";
        ls = "pls";
        cd = "z";
        ssh = "TERM=xterm-256color /usr/bin/ssh";
      };
      shellInit = ''
        # Required for zoxide
        ${pkgs.zoxide}/bin/zoxide init fish | source
      '';
      interactiveShellInit = ''
        # Jump around words easier
        bind \ch backward-word
        bind \cl forward-word

        # Theme (majority is set by stylix)
        set -g theme_nerd_fonts yes
        set -g theme_virtual_env_prompt_enabled no

        if is_ssh_session; and not set -q TMUX
          exec tmux attach
        end
      '';
    };
  };

  home = {
    sessionVariables =
      {
        EDITOR = "${pkgs.neovim}/bin/nvim";
        MANPAGER = "sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'";
        CONF = configDir;
        CODE = "${homeDir}/Code";
        # Shell prompts tend to manage venvs themselves
        VIRTUAL_ENV_DISABLE_PROMPT = 1;
      }
      // (
        if isLinux
        then {
          OS = "Linux";
          ANDROID_SDK_ROOT = "${homeDir}/Android/Sdk";
          ANDROID_HOME = config.home.sessionVariables.ANDROID_SDK_ROOT;
          CHROME_EXECUTABLE = "${pkgs.ungoogled-chromium}/bin/chromium";
        }
        else if isDarwin
        then {
          OS = "Darwin";
          ANDROID_HOME = "/Users/${config.home.username}/Library/Android/sdk";
        }
        else {}
      );

    # Extra stuff to add to $PATH
    sessionPath =
      if isDarwin
      then [
        # homebrew puts all its stuff in this directory instead
        # of /usr/bin or otherwise
        "/opt/homebrew/bin"
      ]
      else [];

    preferXdgDirectories = true;
  };

  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      pictures = "${homeDir}/media";
      music = "${homeDir}/media";
      videos = "${homeDir}/media";
      desktop = null;
      publicShare = null;
      templates = null;
    };
  };

  services.hyprpaper.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

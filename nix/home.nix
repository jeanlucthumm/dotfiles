{
  config,
  pkgs,
  lib,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isArch = builtins.pathExists "/etc/arch-release";
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;
  themeName = config.theme.name;
  themeVariant = config.theme.variant;
in {
  imports = [
    ./theme.nix
  ];

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
      shellAliases =
        {
          vim = "nvim";
          cat = "bat";
          ls = "pls";
          cd = "z";
          ssh = "TERM=xterm-256color /usr/bin/ssh";
        }
        // (
          if isArch
          then {
            pacman = "paru";
          }
          else {}
        );
      shellInit = ''
        # Required for zoxide.
        # Do not put in interactiveShellInit due to bug.
        # Needs to be first.
        ${pkgs.zoxide}/bin/zoxide init fish | source
      '';
      interactiveShellInit = ''
        # Jump around words easier
        bind \ch backward-word
        bind \cl forward-word

        # Theme (majority is set by stylix)
        set -g theme_nerd_fonts yes
        set -g theme_virtual_env_prompt_enabled no

        if [ "$TERM" = "xterm-kitty" ]
            abbr --add -- icat 'kitty +kitten icat'
            alias newterm='kitty --detach --directory (pwd)'
        end

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
        BAT_THEME =
          if themeName == "gruvbox"
          then "gruvbox-${themeVariant}"
          else "base16";
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

  wayland.windowManager.hyprland = {
    enable = true;
    settings = let
      cactive = "rgba(458588ee)";
      cinactive = "rgba(928374ee)";
    in {
      "$mod" = "SUPER";

      input = {
        kb_layout = "us";
        kb_options = "caps:super";
        repeat_rate = 80;
        repeat_delay = 150;

        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;
          scroll_factor = 0.3;
          clickfinger_behavior = true;
          disable_while_typing = true;
        };

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };

      device = {
        name = "pixa3854:00-093a:0274-touchpad";
        sensitivity = 0.4;
      };

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 3;
        layout = "dwindle";
      };

      group = {
        groupbar = {
          gradients = false;
          render_titles = false;
        };
      };

      monitor = [
        ",preferred,auto,1.25"
        "desc:Shenzhen KTC Technology Group M32P10 0000000000001,preferred,auto,1.0"
      ];

      decoration = {
        rounding = 10;
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
      };

      animations = {
        enabled = true;
        bezier = ["myBezier, 0.05, 0.9, 0.1, 1.05"];
        animation = [
          "windows, 1, 5, myBezier"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 5, default"
          "workspaces, 1, 4, default"
        ];
      };

      dwindle = {
        # Master switch for pseudotiling. Enabling is bound to
        # mod + P in the keybinds section below.
        pseudotile = true;
        use_active_for_splits = false;
      };

      gestures = {
        workspace_swipe = true;
      };

      binds = {
        scroll_event_delay = 150;
        # Makes tab go back and forth
        workspace_back_and_forth = true;
        # TODO invert this when https://github.com/hyprwm/Hyprland/issues/2263 is done
        allow_workspace_cycles = true;
      };

      cursor = {
        inactive_timeout = 2;
      };

      exec-once = [
        "kitty --detach --title=\"scratchpad\" --override initial_window_width=235c --override initial_window_height=83c"
      ];

      bind =
        [
          # Software launching
          "$mod, RETURN, exec, kitty"
          "$mod, N, exec, nemo"
          "$mod, C, exec, firefox"
          "$mod, X, exec, qutebrowser"
          "$mod SHIFT, space, togglefloating,"
          "$mod, D, exec, wofi --show drun"

          # Hyprland control
          "$mod, F, fullscreen, 0"
          "$mod, TAB, workspace, previous"
          "$mod, mouse:277, workspace, previous"
          "$mod, G, togglegroup"
          "$mod SHIFT, G, moveoutofgroup"
          "$mod, I, changegroupactive"
          "$mod, P, pseudo, # dwindle"
          "$mod, E, layoutmsg, togglesplit, # dwindle"
          "$mod, Q, killactive,"
          "$mod SHIFT, E, exit,"
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # Software control
          "$mod SHIFT, S, exec, fish ~/.config/hypr/screencap.fish"
          "$mod, BACKSLASH, exec, makoctl dismiss"
          "$mod, B, exec, killall -SIGUSR1 waybar"
          "$mod, V, exec, timew stop; pidof hyprlock || hyprlock"

          # Media control
          ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
          ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
          ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
          ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
          ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9, 0} to [move to] workspace {1..10}
          builtins.concatLists (builtins.genList (
              x: let
                ws = let
                  c = (x + 1) / 10;
                in
                  builtins.toString (x + 1 - (c * 10));
              in [
                "$mod, ${ws}, workspace, ${toString (x + 1)}"
                "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
              ]
            )
            10)
        )
        ++ (
          # Move focus and windows with mod + vim directions
          builtins.concatLists (
            lib.lists.forEach ["H" "L" "K" "J"] (x: let
              dir =
                if x == "H"
                then "l"
                else if x == "L"
                then "r"
                else if x == "K"
                then "u"
                else "d";
            in [
              "$mod, ${x}, movefocus, ${dir}"
              "$mod SHIFT, ${x}, movewindow, ${dir}"
            ])
          )
        );

      # Mouse bindings
      bindm = [
        # Move/resize windows with mod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      windowrulev2 = [
        # Floating
        "float, class:^(kitty)$, title:^(scratchpad)$"
        "float, class:(nemo)"

        # Default to special workspace
        "workspace special, class:^(kitty)$, title:^(scratchpad)$"
      ];
    };

    extraConfig = ''
      # Resize
      bind = $mod, R, submap, resize
      submap = resize
      $resizeInc = 20
      binde = , L, resizeactive, $resizeInc 0
      binde = , H, resizeactive, -$resizeInc 0
      binde = , K, resizeactive, 0 -$resizeInc
      binde = , J, resizeactive, 0 $resizeInc
      bind = , RETURN, submap, reset
      bind = , ESCAPE, submap, reset
      submap = reset

      # Power
      bind = $mod SHIFT, T, submap, power
      submap = power
      bind = , S, exec, systemctl suspend
      bind = , S, submap, reset
      bind = , P, exec, systemctl poweroff
      bind = , P, submap, reset
      bind = , R, exec, systemctl reboot
      bind = , R, submap, reset
      submap = reset

      # Master-Layout
      bind = $mod, M, submap, master
      submap = master
      bind = , RETURN, submap, reset
      bind = $mod, S, layoutmsg, swapwithmaster
      bind = $mod, S, submap, reset
      submap = reset

      # Special workspace
      bind = $mod, S, submap, special
      submap = special
      bind = , RETURN, submap, reset
      bind = $mod, R, togglespecialworkspace
      bind = $mod, R, submap, reset
      submap = reset
    '';
  };

  services = {
    hyprpaper.enable = true;
    swayosd.enable = true;
    # Redlight shifting at night
    gammastep = {
      enable = true;
      dawnTime = "06:00";
      duskTime = "22:00";
      temperature = {
        day = 6500;
        night = 3000;
      };
      provider = "geoclue2";
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

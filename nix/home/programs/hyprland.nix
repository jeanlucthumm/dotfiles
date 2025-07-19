{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # TODO use nix service
    hypridle # Idle manager
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
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
        "DP-1,3840x2160@144,0x0,1"
        "DP-3,3840x2160@60.00,3840x-900,1,transform,3"
      ];

      decoration = {
        rounding = 10;
      };

      ecosystem.no_update_news = true;

      animations = let
        # Default speeds for animations
        primary = toString 1.5;
        secondary = toString 4;
      in {
        enabled = true;
        bezier = ["myBezier, 0.05, 0.9, 0.1, 1.05"];
        animation = [
          "windows, 1, ${primary}, myBezier"
          "windowsOut, 1, ${primary}, default, popin 80%"
          "border, 1, ${secondary}, default"
          "borderangle, 1, ${secondary}, default"
          "fade, 1, ${primary}, default"
          "workspaces, 1, ${primary}, default"
        ];
      };

      dwindle = {
        # Master switch for pseudotiling. Enabling is bound to
        # mod + P in the keybinds section below.
        pseudotile = true;
        use_active_for_splits = false;
      };

      master = {
        new_status = "slave";
        orientation = "right";
        slave_count_for_center_master = 0;
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
        "hypridle"
      ];

      bind =
        [
          # Software launching
          "$mod, RETURN, exec, kitty"
          "$mod, N, exec, nautilus"
          "$mod, C, exec, zen-beta"
          "$mod, X, exec, qutebrowser"
          "$mod SHIFT, space, togglefloating,"
          "$mod, D, exec, wofi --show drun"

          # Hyprland control
          "$mod, F, fullscreen, 0"
          "$mod, TAB, workspace, previous"
          "$mod, mouse:277, workspace, previous"
          "$mod, G, togglegroup"
          "$mod SHIFT, G, moveoutofgroup"
          "$mod SHIFT, I, swapactiveworkspaces, 0 1"
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
          # TODO don't generate, just explicitly list the nums
          # workspaces
          # binds $mod + [shift +] {1..9, 0} to [move to] workspace {1..10}
          builtins.concatLists (
            builtins.genList (
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
            10
          )
        )
        ++ (
          # TODO just iterate of attrs instead of strings for this
          # Move focus with vim directions
          # Move windows with SHIFT + vim directions
          # Swap windows with SHIFT + arrows
          builtins.concatLists (
            lib.lists.forEach ["H" "L" "K" "J"] (
              x: let
                dir =
                  if x == "H"
                  then "l"
                  else if x == "L"
                  then "r"
                  else if x == "K"
                  then "u"
                  else "d";
                arrow =
                  if x == "H"
                  then "LEFT"
                  else if x == "L"
                  then "RIGHT"
                  else if x == "K"
                  then "UP"
                  else "DOWN";
              in [
                "$mod, ${x}, movefocus, ${dir}"
                "$mod SHIFT, ${x}, swapwindow, ${dir}"
                "$mod SHIFT, ${arrow}, movewindow, ${dir}"
              ]
            )
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
        "float, class:^(org.gnome.Nautilus)$"

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

  # Wallpaper manager from same org as Hyprland
  services = {
    hyprpaper.enable = true;
  };

  home.pointerCursor = {
    hyprcursor.enable = true;
    package = pkgs.rose-pine-hyprcursor;
    name = "rose-pine-hyprcursor";
  };
}

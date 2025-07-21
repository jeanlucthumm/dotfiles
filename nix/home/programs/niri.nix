{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.niri = {
    # Enabling happens at system level.
    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            options = "caps:super";
          };
          repeat-delay = 150;
          repeat-rate = 80;
        };
        touchpad = {
          tap = true;
          natural-scroll = true;
          scroll-factor = 0.3;
          click-method = "clickfinger";
        };
        mouse = {
          accel-speed = 0.0;
        };
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "10%";
        };
      };

      # Monitor configuration is pulled from the nix/modules/monitors.nix module
      outputs = with config.monitors; let
        name = monitor: "${monitor.manufacturer} ${monitor.model} ${monitor.serial}";
        cfg = monitor: {
          mode = {
            width = monitor.width;
            height = monitor.height;
            refresh = monitor.refresh;
          };
          position = {
            x = monitor.position_x;
            y = monitor.position_y;
          };
          transform.rotation = monitor.rotation;
        };
      in
        {
          "${name primary}" =
            cfg primary
            // {
              scale = 1.0;
              focus-at-startup = true;
            };
        }
        // lib.optionalAttrs (config.monitors.secondary != null) {
          "${name secondary}" =
            cfg secondary
            // {
              scale = 1.0;
            };
        };

      layout = {
        gaps = 20;
        always-center-single-column = true;
      };

      window-rules = [
        {
          geometry-corner-radius = let
            val = 12.0;
          in {
            top-left = val;
            top-right = val;
            bottom-left = val;
            bottom-right = val;
          };
          clip-to-geometry = true;
        }
      ];

      binds = with config.lib.niri.actions; {
        "Mod+Return".action.spawn = ["kitty"];
        "Mod+C".action.spawn = ["zen-beta"];
        "Mod+X".action.spawn = ["qutebrowser"];
        "Mod+D".action.spawn = ["wofi" "--show" "drun"];

        "Mod+Q".action = close-window;
        "Mod+F".action = maximize-column;
        "Mod+Shift+Space".action = toggle-window-floating;
        "Mod+T".action = toggle-column-tabbed-display;
        "Mod+I".action.spawn = ["niri-toggle-monitor"];

        "Mod+H".action = focus-column-left;
        "Mod+L".action = focus-column-right;
        "Mod+K".action = focus-window-up;
        "Mod+J".action = focus-window-down;

        "Mod+Shift+H".action = move-column-left;
        "Mod+Shift+L".action = move-column-right;
        "Mod+Shift+K".action = move-window-up;
        "Mod+Shift+J".action = move-window-down;

        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;
        "Mod+0".action.focus-workspace = 10;

        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;
        "Mod+Shift+0".action.move-column-to-workspace = 10;

        "Mod+Shift+S".action.spawn = ["niri-screenshot"];
        "Mod+Shift+P".action.spawn = ["hyprlock"];

        "Mod+Shift+E".action = quit;
        "Mod+Backslash".action.spawn = ["makoctl" "dismiss"];

        "XF86AudioRaiseVolume".action.spawn = ["swayosd-client" "--output-volume" "raise"];
        "XF86AudioLowerVolume".action.spawn = ["swayosd-client" "--output-volume" "lower"];
        "XF86AudioMute".action.spawn = ["swayosd-client" "--output-volume" "mute-toggle"];

        "XF86MonBrightnessUp".action.spawn = ["swayosd-client" "--brightness" "raise"];
        "XF86MonBrightnessDown".action.spawn = ["swayosd-client" "--brightness" "lower"];

        "Mod+R".action = switch-preset-column-width;
        "Mod+V".action = consume-window-into-column;
        "Mod+Shift+V".action = expel-window-from-column;

        "Mod+WheelScrollDown" = {
          cooldown-ms = 150;
          action = focus-workspace-down;
        };
        "Mod+WheelScrollUp" = {
          cooldown-ms = 150;
          action = focus-workspace-up;
        };
      };

      prefer-no-csd = true;

      hotkey-overlay = {
        skip-at-startup = true;
      };

      cursor = {
        hide-after-inactive-ms = 5000;
        size = 16;
      };

      spawn-at-startup = [
        {command = ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"];}
        {command = ["${pkgs.swayosd}/bin/swayosd-server"];}
      ];

      environment = {
        DISPLAY = ":0"; # Connects to xwalyand-satellite
        XDG_SESSION_TYPE = "wayland";
      };
    };
  };

  home.packages = with pkgs; [
    xwayland-satellite # For apps that need Xwayland

    # Custom script for toggling between monitors
    (writeShellScriptBin "niri-toggle-monitor" ''
      if niri msg focused-output | grep -q "(DP-1)"; then
        niri msg action focus-monitor-right
      else
        niri msg action focus-monitor-left
      fi
    '')

    # Custom script for taking screenshots
    (writeShellScriptBin "niri-screenshot" ''
      ${grim}/bin/grim -g "$(${slurp}/bin/slurp)" - | ${wl-clipboard}/bin/wl-copy
    '')
  ];

  services = {
    swayosd.enable = true;
  };
}

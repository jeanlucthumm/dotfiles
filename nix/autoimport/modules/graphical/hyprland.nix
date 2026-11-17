# NixOS graphical home manager setup
{jlib, ...}: {
  flake.modules.homeManager.graphical = jlib.mkHomeManager {
    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: {
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        # Each attribute renders as an `hl.<name>(...)` call, one per list
        # element. Binds, submaps and autostart are raw Lua in ./_hyprland.lua.
        settings = {
          config = {
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

            decoration = {
              rounding = 10;
            };

            ecosystem.no_update_news = true;

            animations.enabled = true;

            dwindle = {
              use_active_for_splits = false;
            };

            master = {
              new_status = "slave";
              orientation = "right";
              slave_count_for_center_master = 0;
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
          };

          # TODO: no longer relevant
          device = {
            name = "pixa3854:00-093a:0274-touchpad";
            sensitivity = 0.4;
          };

          monitor = let
            # Hyprland matches a description prefix ("<make> <model> <serial>").
            # A PNP ID missing from the vendor table is "PNP(AOC)" in our monitor
            # data (niri) but plain "AOC" in Hyprland.
            make = monitor: let
              id = builtins.match "PNP\\((.*)\\)" monitor.manufacturer;
            in
              if id == null
              then monitor.manufacturer
              else builtins.head id;
            name = monitor: "desc:${make monitor} ${monitor.model}";
            # Hyprland uses a weird rotation system, so we need to convert
            mkTransform = rotation:
              {
                "0" = 0;
                "90" = 1;
                "180" = 2;
                "270" = 3;
              }.${
                toString rotation
              } or 0;
            s = toString;
            cfg = monitor: {
              output = name monitor;
              mode = "${s monitor.width}x${s monitor.height}@${s monitor.refresh}";
              position = "${s monitor.position_x}x${s monitor.position_y}";
              scale = "1";
              transform = mkTransform monitor.rotation;
            };
          in
            [
              (cfg config.monitors.primary)
            ]
            ++ lib.optionals (
              config.monitors.secondary != null
            ) [
              (cfg config.monitors.secondary)
            ];

          curve._args = [
            "myBezier"
            {
              type = "bezier";
              points = [[0.05 0.9] [0.1 1.05]];
            }
          ];

          animation = let
            # Default speeds for animations
            primary = 1.5;
            secondary = 4;
            mk = leaf: speed: bezier: {
              inherit leaf speed bezier;
              enabled = true;
            };
          in [
            (mk "windows" primary "myBezier")
            (mk "windowsOut" primary "default" // {style = "popin 80%";})
            (mk "border" secondary "default")
            (mk "borderangle" secondary "default")
            (mk "fade" primary "default")
            (mk "workspaces" primary "default")
          ];

          # Three-finger horizontal workspace swipe
          gesture = {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          };

          window_rule = [
            # Floating
            {
              match = {
                class = "^(kitty)$";
                title = "^(scratchpad)$";
              };
              float = true;
            }
            {
              match.class = "^(org.gnome.Nautilus)$";
              float = true;
            }

            # Default to special workspace
            {
              match = {
                class = "^(kitty)$";
                title = "^(scratchpad)$";
              };
              workspace = "special";
            }
          ];
        };

        extraConfig = builtins.readFile ./_hyprland.lua;
      };

      # Wallpaper manager from same org as Hyprland
      services = {
        hyprpaper.enable = true;
      };
    };
  };
}

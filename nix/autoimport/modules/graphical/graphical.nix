# GUI
fp @ {
  jlib,
  withSystem,
  ...
}: {
  flake.modules.nixos.graphical = {
    config,
    pkgs,
    ...
  }: {
    # Fonts
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      font-awesome # for icons
    ];

    services = {
      # Audio management. Modern version of PulseAudio.
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      displayManager.ly = {
        enable = true;
      };

      blueman.enable = true;

      # Configure keymap in X11;
      xserver.xkb = {
        layout = "us";
        variant = "";
      };
    };

    programs = {
      hyprland.enable = true;
      niri.enable = true;
      sway.enable = true;
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # XDG Desktop Portals: Secure gateways for apps to access system features.
    # In Wayland, apps can't directly capture the screen (security). Instead they request
    # access through portals which show permission dialogs and provide controlled access.
    # Without the right portal backend, screen recording apps like Kooha/OBS will fail with
    # "No such interface" errors. Each compositor needs its matching portal implementation.
    xdg.portal = {
      # Desktop integration portal for sandboxed apps (flatpak) to work correctly
      # xdg-desktop-portal-wlr provides screen recording support for wlroots-based compositors like niri
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk # File choosers, notifications, general GTK stuff
        pkgs.xdg-desktop-portal-wlr # ScreenCast/Screenshot for niri (wlroots-based)
      ];
      config = {
        common.default = "gtk";
        # Route specific portal interfaces to the right backend for niri.
        # Note: no `default` here — nixpkgs' niri module sets it to "gnome;gtk",
        # and re-defining it conflicts. We only override the screen-capture backends.
        niri = {
          "org.freedesktop.impl.portal.ScreenCast" = "wlr"; # Screen recording/sharing
          "org.freedesktop.impl.portal.Screenshot" = "wlr"; # Screenshots
        };
      };
    };

    # xdg.portal: since we installed Home Manager via its NixOS module and
    # 'home-manager.useUserPackages' is enabled, we need:
    environment.pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.graphical];
  };

  flake.modules.darwin.graphical = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      raycast
    ];

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.graphical];
  };

  flake.modules.homeManager.graphical = jlib.mkHomeManager {
    generic = {
      config,
      pkgs,
      ...
    }: let
      # `clip` comes from the cli profile (always co-imported at host level).
      copy-last-cmd = pkgs.writeShellScriptBin "copy-last-cmd" ''
        cmd=$(${pkgs.nushell}/bin/nu -c 'history | last | get command')
        output=$(kitty @ get-text --extent last_non_empty_output)
        printf '$ %s\n%s' "$cmd" "$output" | clip
      '';
    in {
      home.packages = with pkgs; let
        system = pkgs.stdenv.hostPlatform.system;
        fpkgs = withSystem system ({config, ...}: config.packages);
      in [
        fpkgs.notify # Cross-platform notifications

        copy-last-cmd
        neovide # Neovim GUI
        ffmpeg # Media processing toolkit
        usbutils # USB utilities
      ];
      xdg.configFile."kitty/auto_pad.py".source = ./_kitty-auto-pad.py;
      programs = {
        # TODO: re-enable on darwin once appstream builds again (nixpkgs Darwin breakage)
        zathura.enable = pkgs.stdenv.hostPlatform.isLinux;

        nushell = {
          # Enables kitty's new key handling protocol in nushell
          settings.use_kitty_protocol = true;
          shellAliases.nv = "neovide --frame transparent --fork";
        };

        # Terminal with GPU acceleration
        kitty = {
          enable = true;
          # See https://github.com/kovidgoyal/kitty/issues/8167
          package =
            if pkgs.stdenv.hostPlatform.isDarwin
            then pkgs.emptyDirectory
            else pkgs.kitty;
          shellIntegration.mode = "no-cursor";

          settings = {
            enable_audio_bell = false;
            bell_on_tab = "🔔 ";
            tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}";
            window_alert_on_bell = true;
            window_padding_width = 8;
            # Auto-centers wide single windows; see _kitty-auto-pad.py
            watcher = "auto_pad.py";
            allow_remote_control = "yes";
            listen_on = "unix:/tmp/kitty";
            repaint_delay = 5;
            input_delay = 1;
            cursor_shape = "block";
            paste_actions = "quote-urls-at-prompt";
            enabled_layouts = "tall:bias=50;full_size=1;mirrored=true";
          };

          actionAliases = {
            kitty_scrollback_nvim = "kitten ${config.home.homeDirectory}/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py";
          };

          keybindings = {
            # Sessions: snapshot tabs/windows/cwds to a file, restore via picker.
            # Overrides rarely-used defaults (paste_from_selection,
            # pass_selection_to_program). Deliberately no --use-foreground-process:
            # restores get fresh shells, never re-run saved commands.
            "kitty_mod+s" = "save_as_session --base-dir ~/.local/share/kitty/sessions";
            "kitty_mod+o" = "goto_session ~/.local/share/kitty/sessions";
            "kitty_mod+h" = "kitty_scrollback_nvim";
            "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
            "kitty_mod+y" = "launch --type=background copy-last-cmd";
            # Like kitty_mod+e (open URL) but copies the URL to clipboard instead
            "kitty_mod+l" = "kitten hints --type url --program @";
            "ctrl+shift+right" = "mouse_select_command_output";
            "shift+enter" = "send_text all \\e\\r";
          };
        };
      };
    };

    darwin = {
      config,
      pkgs,
      ...
    }: let
      # URL opener for kitty: Slack permalinks go straight to the desktop app
      # instead of bouncing through the browser (which leaves stray tabs).
      # Slack's slack:// deep links need the workspace team ID, which isn't in
      # the permalink, so known workspaces are mapped here. The message param
      # is undocumented but verified working (docs only cover channel-level).
      smart-open-url = pkgs.writeShellScriptBin "smart-open-url" ''
        team_for() {
          case "$1" in
            replit) echo T03UB4UGP ;;
          esac
        }

        for url in "$@"; do
          if [[ "$url" =~ ^https://([a-z0-9-]+)\.slack\.com/archives/([A-Z0-9]+)(/p([0-9]+))? ]]; then
            team=$(team_for "''${BASH_REMATCH[1]}")
            if [[ -n "$team" ]]; then
              deep="slack://channel?team=$team&id=''${BASH_REMATCH[2]}"
              ts="''${BASH_REMATCH[4]}"
              # p1785958209167579 -> message=1785958209.167579
              if [[ -n "$ts" ]]; then
                deep+="&message=''${ts:0:-6}.''${ts: -6}"
              fi
              if [[ "$url" =~ [?\&]thread_ts=([0-9.]+) ]]; then
                deep+="&thread_ts=''${BASH_REMATCH[1]}"
              fi
              /usr/bin/open "$deep"
              continue
            fi
          fi
          case "$url" in
            # Linear desktop app: linear:// mirrors the https path
            https://linear.app/*)
              /usr/bin/open "linear://''${url#https://linear.app/}"
              continue
              ;;
            https://linear.review/*)
              /usr/bin/open "linear://review/''${url#https://linear.review/}"
              continue
              ;;
          esac
          /usr/bin/open "$url"
        done
      '';
    in {
      imports = [
        fp.config.flake.modules.homeManager.opt-hammerspoon
      ];

      home.packages = [smart-open-url];

      programs = {
        hammerspoon = {
          enable = true;
          extraConfig = builtins.readFile ./hammerspoon.lua;
        };

        # These are darwin specific because NixOS relies on the WM for splits.
        kitty = {
          settings = {
            macos_option_as_alt = true;
            macos_titlebar_color = "background";
            # macOS GUI apps don't inherit shell PATH, so tell kitty where to find nvim
            exe_search_path = "/etc/profiles/per-user/${config.home.username}/bin";
            # Used by open_url_with_hints (kitty_mod+e) and URL clicks
            open_url_with = "${smart-open-url}/bin/smart-open-url";
          };
          keybindings = {
            "cmd+p" = "previous_tab";
            "cmd+n" = "next_tab";
            "cmd+shift+p" = "move_tab_backward";
            "cmd+shift+n" = "move_tab_forward";
            "cmd+k" = "focus_visible_window";
            "cmd+shift+r" = "set_tab_title";
            "cmd+h" = "previous_window";
            "cmd+l" = "next_window";
            "cmd+enter" = "new_window_with_cwd";
            "cmd+i" = let
              pad = "900";
            in "remote_control set-spacing padding-left=${pad} padding-right=${pad}";
            "cmd+o" = "remote_control set-spacing padding=default";
          };
        };
        nushell.shellAliases.nv = "neovide --frame transparent --fork";
      };
    };
  };
}

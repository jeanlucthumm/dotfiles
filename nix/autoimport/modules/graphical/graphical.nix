# GUI
fp @ {jlib, ...}: {
  flake.modules.nixos.graphical = {
    config,
    pkgs,
    ...
  }: {
    # Configure keymap in X11;
    xserver.xkb = {
      layout = "us";
      variant = "";
    };

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
        # Route specific portal interfaces to the right backend for niri
        niri = {
          default = "gtk";
          "org.freedesktop.impl.portal.ScreenCast" = "wlr"; # Screen recording/sharing
          "org.freedesktop.impl.portal.Screenshot" = "wlr"; # Screenshots
        };
      };
    };

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
        fpkgs = fp.withSystem system ({config, ...}: config.packages);
      in [
        fpkgs.notify # Cross-platform notifications

        copy-last-cmd
        neovide # Neovim GUI
        ffmpeg # Media processing toolkit
        usbutils # USB utilities
      ];

      programs.zathura.enable = true;

      programs.nushell = {
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
        shellIntegration.enableFishIntegration = true;
        shellIntegration.mode = "no-cursor";

        settings = {
          enable_audio_bell = false;
          bell_on_tab = "🔔 ";
          tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}";
          window_alert_on_bell = true;
          window_padding_width = 8;
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
          "kitty_mod+h" = "kitty_scrollback_nvim";
          "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
          "kitty_mod+y" = "launch --type=background copy-last-cmd";
          "ctrl+shift+right" = "mouse_select_command_output";
          "shift+enter" = "send_text all \\e\\r";
        };
      };

      zathura.enable = true;

      # Enables using Kitty's new key handling protocol in nushell
      nushell.settings.use_kitty_protocol = true;
    };

    darwin = {config, ...}: {
      imports = [
        fp.config.flake.modules.homeManager.opt-hammerspoon
      ];

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
          };
        };
        nushell.shellAliases.nv = "neovide --frame transparent --fork";
      };
    };
  };
}

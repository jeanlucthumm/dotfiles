# GUI
fps: {
  flake.modules.nixos.generic = {
    config,
    pkgs,
    ...
  }: {
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
  flake.modules.nixos.graphical = {
    # Configure keymap in X11;
    xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };

  flake.modules.darwin.graphical = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      raycast
    ];
  };

  flake.modules.homeManager.graphical = {
    config,
    pkgs,
    lib,
    ...
  }:
    fps.jlib.mkHomeManager pkgs {
      generic = let
        # `clip` comes from the cli profile (always co-imported at host level).
        copy-last-cmd = pkgs.writeShellScriptBin "copy-last-cmd" ''
          cmd=$(${pkgs.nushell}/bin/nu -c 'history | last | get command')
          output=$(kitty @ get-text --extent last_non_empty_output)
          printf '$ %s\n%s' "$cmd" "$output" | clip
        '';
      in {
        home.packages = with pkgs; [
          copy-last-cmd
          neovide # Neovim GUI
          notify # Cross-platform notifications
          ffmpeg # Media processing toolkit
          usbutils # USB utilities
        ];

        programs.zathura.enable = true;
      };

      darwin = {
        imports = [
          fps.config.flake.modules.homeManager.opt-hammerspoon
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

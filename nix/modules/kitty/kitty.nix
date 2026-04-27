# Kitty — graphical contribution (cross-platform)
{
  flake.modules.homeManager.graphical = p: {
    programs.kitty = {
      enable = true;
      # See https://github.com/kovidgoyal/kitty/issues/8167
      package =
        if p.pkgs.stdenv.hostPlatform.isDarwin
        then p.pkgs.emptyDirectory
        else p.pkgs.kitty;
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
        kitty_scrollback_nvim = "kitten ${p.config.home.homeDirectory}/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py";
      };

      keybindings = {
        "kitty_mod+h" = "kitty_scrollback_nvim";
        "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
        "kitty_mod+y" = "launch --type=background copy-last-cmd";
        "ctrl+shift+right" = "mouse_select_command_output";
        "shift+enter" = "send_text all \\e\\r";
      };
    };
  };
}

# System agnostic GUI programs
{
  pkgs,
  config,
  ...
}: {
  programs = {
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
        enable_audio_bell = true;
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
        "ctrl+shift+right" = "mouse_select_command_output";
      };
    };

    # Enables using Kitty's new key handling protocol in nushell
    nushell.settings.use_kitty_protocol = true;
  };
}

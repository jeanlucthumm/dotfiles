# System agnostic GUI programs
{pkgs, ...}: {
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
        allow_remote_control = false;
        repaint_delay = 5;
        input_delay = 1;
        cursor_shape = "block";
        scrollback_pager = "nvim -c 'set ft=sh' -";
        paste_actions = "quote-urls-at-prompt";
        enabled_layouts = "tall:bias=50;full_size=1;mirrored=false";
      };
    };

    # Enables using Kitty's new key handling protocol in nushell
    nushell.settings.use_kitty_protocol = true;
  };
}

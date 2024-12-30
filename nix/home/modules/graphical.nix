# System agnostic GUI programs
{pkgs, ...}: {
  home.packages = with pkgs; [
    neovide # Neovim GUI
  ];

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
        macos_option_as_alt = true;
        scrollback_pager = "nvim -c 'set ft=sh' -";
        paste_actions = "quote-urls-at-prompt";
      };
    };
  };
}

{pkgs, ...}: {
  imports = [
    ./fish.nix
    ./nushell
  ];

  home.packages = with pkgs; [
    ripgrep # Fast grep search tool
    nodejs_22 # A bunch of tools (including Copilot) rely on this
    sumneko-lua-language-server # Lua language server
    tree-sitter # Syntax parser extensively used by NeoVim

    ## GUI
    neovide # Neovim GUI
  ];

  programs = {
    kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;
      shellIntegration.mode = "no-cursor";

      settings = {
        enable_audio_bell = true;
        window_padding_width = 8;
        allow_remote_control = false;
        repaint_delay = 5;
        input_delay = 1;
        cursor_shape = "blocK";
        macos_option_as_alt = true;
        scrollback_pager = "nvim -c 'set ft=sh' -";
        paste_actions = "quote-urls-at-prompt";
      };
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

# Minimal CLI setup - bare essentials for a usable remote server
{pkgs, ...}: {
  imports = [
    ../../programs/nushell/foundation.nix
  ];

  home.packages = with pkgs; [
    neovim # IDE (tExT eDiToR)
    tmux # Terminal multiplexer
    htop # Interactive process viewer
    python3 # The language python
    wget # Download files from the web
    unzip # Unzip files
    dig # DNS lookup utility
    jq # Command-line JSON processor
  ];

  home.sessionVariables = {
    EDITOR = "${pkgs.neovim}/bin/nvim";
  };
}

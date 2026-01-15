# Sys administration CLI setup
{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    manix # CLI for nix docs
    yadm # Dotfile manager
    nix-prefetch-git # Utility for populating nix fetchgit expressions
    alejandra # Nix formatter
    nil # Nix LSP
    nix-update # Nix overlay updater
  ];

  programs = {
    # Modern nix CLI wrapper
    nh = {
      enable = true;
      flake = config.home.homeDirectory + "/nix";
    };
  };
}

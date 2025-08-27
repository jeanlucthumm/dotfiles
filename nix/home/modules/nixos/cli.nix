# NixOS CLI setup
{pkgs, ...}: {
  imports = [
    ../../programs/nushell/nixos.nix
  ];

  programs.fish.enable = true;

  home.packages = with pkgs; [
    keyutils # Kernel key services
    bitwarden-cli # Bitwarden CLI
  ];
}

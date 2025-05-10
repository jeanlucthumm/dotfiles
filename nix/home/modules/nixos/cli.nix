# NixOS CLI setup
{pkgs, ...}: {
  imports = [
    ../../programs/nushell/nixos.nix
  ];

  home.packages = with pkgs; [
    keyutils # Kernel key services
    bitwarden-cli # Bitwarden CLI
  ];
}

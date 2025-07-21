{pkgs, ...}: {
  imports = [
    ../modules/nixos/foundation.nix
    ../modules/cli.nix
    ../modules/ssh.nix
    ../modules/nixos/security.nix
  ];

  # Server-specific packages
  home.packages = with pkgs; [
    reddit-easy-post # YAML to Reddit posting CLI
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

{...}: {
  imports = [
    ../modules/foundation.nix
    ../modules/nixos-foundation.nix
    ../modules/cli.nix
    ../modules/ssh.nix
    ../modules/theme-home.nix
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

{pkgs, ...}: {
  imports = [
    ../modules/nixos/foundation.nix
    ../modules/cli/foundation.nix
    ../modules/cli/sysadmin.nix
    ../modules/ssh.nix
  ];
  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

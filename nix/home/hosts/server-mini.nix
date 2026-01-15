{pkgs, ...}: {
  imports = [
    ../modules/nixos/foundation.nix
    ../modules/cli/foundation.nix
    ../modules/cli/sysadmin.nix
    ../modules/ssh.nix
  ];

  home.packages = with pkgs; [
    smartmontools
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

{...}: {
  imports = [
    ../modules/foundation.nix
    ../modules/nixos-foundation.nix
    ../modules/cli.nix
    ../modules/nixos-graphical.nix
    ../modules/graphical.nix
    ../modules/ssh.nix
    ../modules/theme-home.nix
    ../../hosts/desktop/theme-setting.nix
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

{...}: {
  imports = [
    ../modules/cli.nix
    ../modules/nixos-foundation.nix
    ../modules/nixos-graphical.nix
    ../modules/graphical.nix
    ../../hosts/desktop/theme-setting.nix
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

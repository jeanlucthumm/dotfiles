{...}: {
  imports = [
    ./desktop_monitors.nix
    ../modules/nixos/foundation.nix
    ../modules/cli
    ../modules/nixos/cli.nix
    ../modules/nixos/graphical.nix
    ../modules/graphical.nix
    ../modules/ssh.nix
    ../modules/theme-home.nix
    ../modules/syncing.nix
    ../modules/security.nix
    ../modules/llm.nix
    ../modules/nixos/security.nix
    ../programs/taskwarrior
    ../modules/logitech-mx.nix
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

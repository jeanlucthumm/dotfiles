{lib, ...}: {
  imports = [
    ../modules/nixos/foundation.nix
    ../modules/cli.nix
    ../modules/nixos/cli.nix
    ../modules/nixos/graphical.nix
    ../modules/graphical.nix
    ../modules/ssh.nix
    ../modules/theme-home.nix
    ../modules/syncing.nix
    ../modules/security.nix
    ../modules/llm.nix
    ../modules/nixos/security.nix
    ../modules/programs/taskwarrior
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";

  # TODO remove this once build failure is resolved.
  # https://github.com/NixOS/nixpkgs/issues/418689
  programs.qutebrowser.enable = lib.mkForce false;
}

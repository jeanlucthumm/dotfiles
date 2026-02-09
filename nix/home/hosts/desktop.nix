{...}: let
  keys = import ../../secrets/pubkeys.nix;
in {
  imports = [
    ./desktop_monitors.nix
    ../modules/nixos/foundation.nix
    ../modules/cli
    ../modules/nixos/cli.nix
    ../modules/nixos/graphical.nix
    ../modules/nixos/dictation.nix
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

  programs.git.signing = {
    key = "key::${keys.desktop.fido2.signing}";
    format = "ssh";
  };

  age.identityPaths = [
    ../../secrets/desktop-yubikey-identity.txt
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

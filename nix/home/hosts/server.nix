{pkgs, inputs, ...}: {
  imports = [
    ../modules/nixos/foundation.nix
    ../modules/cli
    ../modules/ssh.nix
    ../modules/nixos/security.nix
    ../programs/clawdbot.nix
  ];

  # Server-specific packages
  home.packages = with pkgs; [
    reddit-easy-post # YAML to Reddit posting CLI
  ];

  # Helper script for restoring data from backups
  home.file."restore.sh" = {
    source = ../../system/hosts/server/restore.sh;
    executable = true;
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

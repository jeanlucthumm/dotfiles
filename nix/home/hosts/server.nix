{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../modules/nixos/foundation.nix
    ../modules/cli
    ../modules/ssh.nix
    ../modules/nixos/security.nix
  ];

  # Server-specific packages
  home.packages = with pkgs; [
    claude-code # Claude CLI (OAuth creds in ~/.claude, gateway runs as system service)
    reddit-easy-post # YAML to Reddit posting CLI
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

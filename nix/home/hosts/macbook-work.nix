{...}: {
  imports = [
    ../modules/darwin/foundation.nix
    ../modules/darwin/nushell.nix
    ../modules/cli
    ../modules/graphical.nix
    ../modules/darwin/graphical.nix
    ../modules/llm.nix
    ../modules/theme-home.nix
    ../modules/ssh.nix
  ];

  home.stateVersion = "24.05";
}

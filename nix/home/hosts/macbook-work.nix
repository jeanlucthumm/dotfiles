{lib, pkgs, inputs, ...}: {
  imports = [
    ../modules/darwin/foundation.nix
    ../modules/darwin/nushell.nix
    ../modules/cli
    ../modules/graphical.nix
    ../modules/darwin/graphical.nix
    ../modules/llm.nix
    ../modules/theme-home.nix
    ../modules/ssh.nix
    ../programs/taskwarrior/common.nix
    inputs.dotfiles-private.homeModules.work
  ];

  home.packages = with pkgs; [_1password-cli pnpm];

  # No FIDO2 security key on work laptop — waiting for sk setup on this host
  programs.git.signing.signByDefault = lib.mkForce false;

  home.stateVersion = "24.05";
}

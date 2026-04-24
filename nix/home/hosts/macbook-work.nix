{lib, pkgs, inputs, ...}: {
  imports = [
    ../modules/darwin/foundation.nix
    ../modules/darwin/nushell.nix
    ../modules/cli
    ../modules/graphical.nix
    ../modules/darwin/graphical.nix
    ../modules/llm.nix
    ../modules/theme-home.nix
    # ssh.nix not imported — work SSH config is handled by dotfiles-private
    ../programs/taskwarrior/common.nix
    inputs.dotfiles-private.homeModules.work
  ];

  home.packages = with pkgs; [_1password-cli pnpm ngrok google-cloud-sdk sem];

  # No FIDO2 security key on work laptop — waiting for sk setup on this host
  programs.git.signing.signByDefault = lib.mkForce false;
  programs.git.signing.format = null;

  gtk.gtk4.theme = null;

  home.stateVersion = "24.05";
}

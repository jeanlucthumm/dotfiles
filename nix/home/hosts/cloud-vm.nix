# Cloud VM dev profile - headless remote VMs
# Username is "developer", no secrets/YubiKey/signing available.
{pkgs, lib, ...}: {
  imports = [
    ../modules/cli/foundation.nix
    ../modules/cli/dev.nix
    ../modules/cli/qol.nix
    ../modules/cli/sysadmin.nix
    ../modules/llm.nix
    ../modules/ssh.nix
  ];

  # No signing keys on cloud VMs
  programs.git.signing.signByDefault = lib.mkForce false;

  home.username = "developer";
  home.homeDirectory = "/home/developer";
  home.stateVersion = "24.05";
}

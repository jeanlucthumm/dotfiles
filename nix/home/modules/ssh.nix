# Shared SSH config (imported by both NixOS and Darwin).
# Platform-specific SSH setup lives in nixos/ssh.nix and darwin/ssh.nix.
{...}: {
  programs.ssh.matchBlocks."*" = {
    controlMaster = "auto";
    controlPath = "~/.ssh/sockets/%r@%h-%p";
    controlPersist = "4h";
  };
}

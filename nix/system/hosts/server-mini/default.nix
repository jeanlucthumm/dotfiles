# Minimal ZFS backup receiver - receives replication from main server
{pkgs, ...}: {
  imports = [
    ./disko-config.nix
    ./hardware-configuration.nix
    ../../modules/foundation.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/tailscale.nix
    ../../modules/user-jeanluc.nix
    ../../modules/boot.nix
    ../../modules/zfs.nix
  ];

  networking.hostName = "server-mini";
  networking.hostId = "3333bb65";

  users.users.root.openssh.authorizedKeys.keys = (import ../../../secrets/pubkeys.nix).all;

  environment.systemPackages = with pkgs; [
    smartmontools # disk health monitoring
  ];

  system.stateVersion = "24.05";
}

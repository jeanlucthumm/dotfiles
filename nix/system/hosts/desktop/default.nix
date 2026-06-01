{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/bluetooth.nix
    ../../modules/containers.nix
    ../../modules/graphical.nix
    ../../modules/foundation.nix
    ../../modules/graphical.nix
    ../../modules/security.nix
    ../../modules/ssh.nix
    ../../modules/tailscale.nix
    ../../modules/user-jeanluc.nix
    ../../modules/boot.nix
    ../../modules/amd-gpu.nix
    ../../modules/agenix.nix
    ../../modules/theme-system.nix
    ../../modules/secrets.nix
    ../../modules/neo4j.nix
    ../../modules/logitech-mx.nix
    ./hardware-configuration.nix
    ./theme-setting.nix
  ];
}

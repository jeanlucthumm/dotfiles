# Build: nix build .#nixosConfigurations.iso.config.system.build.isoImage
# Write to USB: sudo dd if=./result/iso/nixos-custom-*.iso of=/dev/sdX bs=4M status=progress
{
  config,
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}: let
  pubkeys = import ../../secrets/pubkeys.nix;
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # Minimal tools in the live environment
  environment.systemPackages = with pkgs; [
    tmux
  ];

  # Stable hostname + mDNS for easy discovery (nixos-ssh-bootstrap.local)
  networking.hostName = "nixos-ssh-bootstrap";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
  };

  # SSH access for nixos-anywhere: root over key-only SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = pubkeys.all;
  networking.firewall.allowedTCPPorts = [22];

  # Auto-login on the first virtual console as the `nixos` user
  services.getty.autologinUser = "nixos";

  # Add a helpful message at login
  environment.etc."issue".text = ''

    Welcome to the NixOS SSH bootstrap ISO
    ======================================

    This ISO is meant to:
      - boot a machine
      - bring up networking
      - expose root over SSH (key-only)
      - let you run nixos-anywhere from another machine

    On your laptop, connect with:
      ssh root@nixos-ssh-bootstrap.local

  '';

  # ISO-specific settings
  image = {
    fileName = lib.mkForce "nixos-custom-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  };

  # ISO volume ID
  isoImage.volumeID = lib.mkForce "NIXOS_CUSTOM";
}

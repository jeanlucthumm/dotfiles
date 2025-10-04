# Build: nix build .#nixosConfigurations.iso.config.system.build.isoImage
# Write to USB: sudo dd if=./result/iso/nixos-custom-*.iso of=/dev/sdX bs=4M status=progress
{
  config,
  pkgs,
  lib,
  ...
}: let
  pubkeys = import ../../secrets/pubkeys.nix;

  # Script to set up SSH keys on the installed system
  setupRootSSH = pkgs.writeShellScriptBin "setup-root-ssh" ''
    #!/bin/sh
    set -e

    echo "Setting up root SSH access on installed system..."

    if [ ! -d /mnt/root ]; then
      mkdir -p /mnt/root
    fi

    if [ ! -d /mnt/root/.ssh ]; then
      mkdir /mnt/root/.ssh
    fi

    cat > /mnt/root/.ssh/authorized_keys <<EOF
    ${lib.concatStringsSep "\n" pubkeys.all}
    EOF

    chmod 700 /mnt/root/.ssh
    chmod 600 /mnt/root/.ssh/authorized_keys
    chown 0:0 /mnt/root/.ssh /mnt/root/.ssh/authorized_keys

    echo "✓ Root authorized_keys configured at /mnt/root/.ssh/authorized_keys"
    echo "  Added ${toString (builtins.length pubkeys.all)} SSH keys"
  '';
in {
  imports = [
    "${pkgs.path}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Add the setup script to the live environment
  environment.systemPackages = with pkgs; [
    setupRootSSH
    git
    tmux
  ];

  # Add a helpful message at login
  environment.etc."issue".text = ''

    Welcome to NixOS Custom Installer
    ==================================

    After running 'nixos-install', run:
      setup-root-ssh

    This will configure SSH access for root on the installed system.

  '';

  # ISO-specific settings
  isoImage = {
    isoName = lib.mkForce "nixos-custom-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
    volumeID = lib.mkForce "NIXOS_CUSTOM";
  };
}

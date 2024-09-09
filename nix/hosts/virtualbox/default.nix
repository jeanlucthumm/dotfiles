{ config, pkgs, ... }: {
  imports = [
    ../default-nixos
    ./hardware-configuration.nix
    ./theme-setting.nix
  ];

  networking.hostName = "virtualbox";
}

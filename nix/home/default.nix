{ config, pkgs, lib, ... }:
{
  imports = [
    ./common.nix
    ./fish.nix
  ];
  # TODO conditional import of linux and hyprland
}

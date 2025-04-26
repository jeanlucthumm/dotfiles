# NixOS CLI setup
{pkgs, ...}: {
  home.packages = with pkgs; [
    keyutils
  ];
}

# Configuration for fish
{ pkgs, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isArch = isLinux && (builtins.pathExists "/etc/arch-release");
in {
  enable = true;
  shellAliases = (if isArch then { pacman = "paru"; } else { });
}

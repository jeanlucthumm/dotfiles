# Nushell
{pkgs, ...}: {
  flake.modules.homeManager.nushell = {
    home.packages = [pkgs.nushell];
  };
}

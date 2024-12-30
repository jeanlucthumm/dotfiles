# Foundational settings for NixOS.
{hostName, ...}: {
  programs = {
    fish.shellAliases.nrs = "sudo nixos-rebuild switch --flake $HOME/nix#${hostName}";
    nushell.configFile.text = ''
      def nrs [] {
          sudo nixos-rebuild switch --flake $"($env.HOME)/nix#${hostName}"
      }
    '';
  };

  home.sessionVariables = {
    OS = "Linux";
  };
}

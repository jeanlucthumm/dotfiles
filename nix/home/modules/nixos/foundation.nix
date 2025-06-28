# Foundational settings for NixOS.
{hostName, ...}: {
  programs = {
    nushell.configFile.text = ''
      def nrs []: [nothing -> nothing] {
          sudo nixos-rebuild switch --flake $"($env.HOME)/nix#${hostName}"
      }
    '';
  };
}

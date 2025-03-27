# Foundational settings for NixOS.
{
  pkgs,
  hostName,
  ...
}: {
  home.packages = with pkgs; [
    appimage-run # Allows for running .AppImage
  ];

  programs = {
    fish.shellAliases.nrs = "sudo nixos-rebuild switch --flake $HOME/nix#${hostName}";
    nushell.configFile.text = ''
      def nrs []: [nothing -> nothing] {
          sudo nixos-rebuild switch --flake $"($env.HOME)/nix#${hostName}"
      }
    '';
  };

  home.sessionVariables = {
    OS = "Linux";
  };
}

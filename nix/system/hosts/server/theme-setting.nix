{pkgs, ...}: {
  imports = [
    ../../modules/theme.nix
  ];

  theme = {
    enable = true;
    name = "gruvbox";
    darkMode = false;
    fontCoding = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 10;
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
  };
}

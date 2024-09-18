{...}: {
  imports = [
    ../../theme.nix
  ];
  theme = {
    enable = true;
    name = "gruvbox";
    darkMode = true;
    fontCoding = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };
  };
}

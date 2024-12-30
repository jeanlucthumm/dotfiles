{...}: {
  imports = [
    ../../theme.nix
  ];
  theme = {
    enable = true;
    name = "gruvbox";
    darkMode = false;
    fontCoding = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };
  };
}

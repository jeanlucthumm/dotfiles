{config, ...}: {
  imports = [
    ./theme.nix
  ];
  theme = {
    enable = true;
    name = "gruvbox";
    variant = "dark";
  };
}

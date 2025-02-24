{pkgs, ...}: {
  imports = [
    ../../modules/theme.nix
  ];
  theme = let
    # Externalizes some theme settings outside of VCS.
    # Helpful when they change frequently.
    localSettings =
      if builtins.pathExists ./theme-setting-local.nix
      then import ./theme-setting-local.nix
      else {darkMode = true;};
  in {
    enable = true;
    inherit (localSettings) darkMode;
    name = "gruvbox";
    fontCoding = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 10;
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
  };
}

{lib, pkgs, ...}: {
  imports = [
    ../../modules/theme.nix
  ];

  theme = let
    # Externalizes some theme settings outside of VCS.
    # Helpful when they change frequently.
    localSettings = lib.optionalAttrs (builtins.pathExists ./theme-setting-local.nix) (import ./theme-setting-local.nix);
    defaults = {
      enable = true;
      name = "gruvbox";
      darkMode = true;
      fontCoding = {
        name = "JetBrainsMono Nerd Font Mono";
        size = 10;
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
    };
  in
    defaults // localSettings;
}

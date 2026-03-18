{lib, ...}: {
  imports = [
    ../../modules/theme.nix
  ];

  theme = let
    localSettings = lib.optionalAttrs (builtins.pathExists ./theme-setting-local.nix) (import ./theme-setting-local.nix);
    defaults = {
      enable = true;
      name = "rose-pine";
      darkMode = true;
    };
  in
    defaults // localSettings;
}

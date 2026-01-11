{lib, ...}: {
  imports = [
    ../../modules/theme.nix
  ];

  theme = let
    # Externalizes some theme settings outside of VCS.
    # Helpful when they change frequently.
    localSettings = lib.optionalAttrs (builtins.pathExists ./theme-setting-local.nix) (import ./theme-setting-local.nix);
    defaults = {
      enable = true;
      name = "rose-pine";
      darkMode = true;
      # variant = "moon";  # Uncomment for moon variant
    };
  in
    defaults // localSettings;
}

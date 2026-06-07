# Custom library functions
{lib, ...}: {
  _module.args.jlib = {
    # Creates per system home manager config
    mkHomeManager = pkgs: {
      generic ? null,
      darwin ? null,
      nixos ? null,
    }:
      lib.mkMerge [
        (lib.mkIf (generic != null) generic)
        (lib.mkIf (darwin != null && pkgs.hostPlatform.isDarwin) darwin)
        (lib.mkIf (nixos != null && pkgs.hostPlatform.isLinux) nixos)
      ];

    # Easy ignored themeing
    withLocalThemeOverride = default: let
      localSettings = lib.optionalAttrs (builtins.pathExists ./theme-setting-local.nix) (import ./theme-setting-local.nix);
    in
      default // localSettings;
  };
}

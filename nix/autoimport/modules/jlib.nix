# Custom library functions
{lib, ...}: {
  _module.args.jlib = {
    # Creates per system home manager config
    mkHomeManager = {
      generic ? null, # module func or attrs
      darwin ? null, # module func or attrs
      nixos ? null, # module func or attrs
    }: {
      # We use filtered imports list so that the module system doesn't encounter null as an entry
      # Which can happen with a bare lib.mkMerge and lib.mkIf combo.
      #
      # Moreover, because our condition depends on `pkgs` which comes from module args, which
      # requires `config` to be resolved already, which in turn requires imports to be resolved,
      # we can't just filter directly in the imports list.
      #
      # Only the _body_ of each imported module is allowed to reference pkgs, so we move the
      # condition there.
      imports =
        lib.optional (generic != null) generic
        ++ lib.optional (darwin != null) ({pkgs, ...} @ args: {
          config =
            lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
            (
              if lib.isFunction darwin
              then darwin args
              else darwin
            );
        })
        ++ lib.optional (nixos != null) ({pkgs, ...} @ args: {
          config =
            lib.mkIf pkgs.stdenv.hostPlatform.isLinux
            (
              if lib.isFunction nixos
              then nixos args
              else nixos
            );
        });
    };

    # Easy ignored themeing
    withLocalThemeOverride = default: let
      localSettings = lib.optionalAttrs (builtins.pathExists ./theme-setting-local.nix) (import ./theme-setting-local.nix);
    in
      default // localSettings;
  };
}

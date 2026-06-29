# Custom library functions
{lib, ...}: {
  _module.args.jlib = {
    # Creates per system home manager config.
    #
    # This relies on _conditional imports_ so that we create a shell hm module
    # that imports the param modules only on the right system.
    #
    # The big gotcha with this is that imports cannot depend on `config` or `pkgs` which is where
    # you would normally get `system` from.
    #
    # So instead, we thread that into the module evaluator via specialArg.
    mkHomeManager = {
      generic ? null, # module func or attrs
      darwin ? null, # module func or attrs
      nixos ? null, # module func or attrs
    }: ({system, ...}: let
      hostPlatform = lib.systems.elaborate system;
    in {
      imports =
        lib.optional (generic != null) generic
        ++ lib.optionals (darwin != null && hostPlatform.isDarwin) [darwin]
        ++ lib.optionals (nixos != null && hostPlatform.isLinux) [nixos];
    });

    # Easy ignored themeing
    withLocalThemeOverride = default: let
      localSettings = lib.optionalAttrs (builtins.pathExists ./theme-setting-local.nix) (import ./theme-setting-local.nix);
    in
      default // localSettings;
  };
}

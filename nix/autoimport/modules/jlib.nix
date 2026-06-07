# Custom library functions
{lib, ...}: {
  _module.args.jlib = {
    # Creates per system home manager config
    mkHomeManager = {
      generic ? null, # module func or attrs
      darwin ? null, # module func or attrs
      nixos ? null, # module func or attrs
    }: let
      # Wraps a module so its `config` only applies when `cond pkgs` is true.
      # `options` and `imports` apply unconditionally (declaring unused options is
      # harmless; nested imports must themselves be platform-safe).
      #
      # We can't gate via `imports = lib.optional ...` because that would force
      # `pkgs` while resolving imports (pkgs ← _module.args ← config ← imports = ∞).
      # Gating inside the body defers the pkgs reference past import resolution.
      gate = cond: mod: ({pkgs, ...} @ args: let
        inner =
          if lib.isFunction mod
          then mod args
          else mod;
        isModuleForm =
          builtins.isAttrs inner
          && (inner ? imports || inner ? options || inner ? config);
        cfg =
          if isModuleForm
          then (inner.config or {})
          else inner;
      in {
        options = lib.optionalAttrs isModuleForm (inner.options or {});
        imports = lib.optionals isModuleForm (inner.imports or []);
        config = lib.mkIf (cond pkgs) cfg;
      });
    in {
      imports =
        lib.optional (generic != null) generic
        ++ lib.optional (darwin != null) (gate (pkgs: pkgs.stdenv.hostPlatform.isDarwin) darwin)
        ++ lib.optional (nixos != null) (gate (pkgs: pkgs.stdenv.hostPlatform.isLinux) nixos);
    };

    # Easy ignored themeing
    withLocalThemeOverride = default: let
      localSettings = lib.optionalAttrs (builtins.pathExists ./theme-setting-local.nix) (import ./theme-setting-local.nix);
    in
      default // localSettings;
  };
}

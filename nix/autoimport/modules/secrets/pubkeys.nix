{lib, ...}: {
  options.flake.pubkeys = lib.mkOption {
    type = lib.types.attrs;
  };

  config.flake.pubkeys = import ./_pubkeys.nix;
}

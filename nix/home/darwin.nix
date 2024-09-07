{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./modules/common.nix
    ./modules/fish.nix
    ./modules/darwin-fish-fix.nix
  ];
}

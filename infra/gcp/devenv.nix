{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  packages = with pkgs; [pkgs.opentofu];
}

{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default];
}

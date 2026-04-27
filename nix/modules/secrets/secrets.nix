{inputs, ...}: {
  flake.modules.nixos.secrets = {pkgs, ...}: {
    imports = [
      inputs.agenix.nixosModules.default
    ];

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age-plugin-yubikey
    ];
  };

  flake.modules.darwin.secrets = {pkgs, ...}: {
    imports = [
      inputs.agenix.darwinModules.default
    ];

    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.age-plugin-yubikey
    ];
  };
}

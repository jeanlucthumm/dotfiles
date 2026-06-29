fp @ {withSystem, ...}: {
  flake.homeConfigurations."developer@cloud-vm" = withSystem "x86_64-linux" ({
    pkgs,
    system,
    ...
  }:
    fp.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit system; # required to make jlib.mkHomeManager work
      };
      modules = with fp.config.flake.modules.homeManager; [
        base
        dev
        ({lib, ...}: {
          # No signing keys on cloud VMs
          programs.git.signing.signByDefault = lib.mkForce false;

          home.username = "developer";
          home.homeDirectory = "/home/developer";
          home.stateVersion = "24.05";
        })
      ];
    });
}

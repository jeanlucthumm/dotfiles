fp @ {withSystem, ...}: {
  flake.homeConfigurations."developer@cloud-vm" = withSystem "x86_64-linux" ({pkgs, ...}:
    fp.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
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

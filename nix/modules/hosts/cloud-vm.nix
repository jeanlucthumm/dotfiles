fp: {
  flake.homeConfigurations."developer@cloud-vm" = fp.inputs.home-manager.lib.homeManagerConfiguration {
    modules = with fp.config.flake.modules.homeManager; [
      base
      dev
      {
        # No signing keys on cloud VMs
        programs.git.signing.signByDefault = lib.mkForce false;

        home.username = "developer";
        home.homeDirectory = "/home/developer";
        home.stateVersion = "24.05";
      }
    ];
  };
}

fp: {
  flake.deploy = {
    nodes = {
      server = {
        hostname = "server.lan";
        sshUser = "jeanluc";
        user = "root";
        # wheel group has passwordless sudo on server, so interactive sudo prompts are unnecessary
        interactiveSudo = false;
        profiles.system = {
          path =
            fp.inputs.deploy-rs.lib.x86_64-linux.activate.nixos
            fp.config.flake.nixosConfigurations.server;
        };
      };
    };
  };

  flake.checks =
    builtins.mapAttrs (system: deployLib: deployLib.deployChecks fp.config.flake.deploy)
    fp.inputs.deploy-rs.lib;
}

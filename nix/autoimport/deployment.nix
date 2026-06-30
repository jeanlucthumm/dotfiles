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

  # Only emit deploy checks under the systems we actually deploy to. Mapping over
  # all of deploy-rs.lib would place the x86_64-linux server activation under
  # checks.aarch64-darwin too, so `nix flake check` on the macbook tries to build
  # an x86_64-linux derivation and fails with a platform mismatch.
  flake.checks.x86_64-linux =
    fp.inputs.deploy-rs.lib.x86_64-linux.deployChecks fp.config.flake.deploy;
}

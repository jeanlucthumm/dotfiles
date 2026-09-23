fp @ {lib, ...}: let
  # Which nodes belong to which system, for the per-system checks below.
  nodesBySystem = {
    x86_64-linux = ["server"];
    aarch64-darwin = ["macmini"];
  };
in {
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

      macmini = {
        hostname = "macmini";
        sshUser = "jeanluc";
        user = "root";
        interactiveSudo = false;
        profiles.system = {
          path =
            fp.inputs.deploy-rs.lib.aarch64-darwin.activate.darwin
            fp.config.flake.darwinConfigurations.macmini;
        };
      };
    };
  };

  # deployChecks builds every node's activation, so each system only gets the
  # nodes it can build: otherwise `nix flake check` on the macbook would try to
  # build the x86_64-linux server closure and fail with a platform mismatch.
  flake.checks =
    lib.mapAttrs (
      system: names:
        fp.inputs.deploy-rs.lib.${system}.deployChecks (fp.config.flake.deploy
          // {
            nodes = lib.filterAttrs (n: _: lib.elem n names) fp.config.flake.deploy.nodes;
          })
    )
    nodesBySystem;
}

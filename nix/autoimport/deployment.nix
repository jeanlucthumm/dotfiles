fp @ {lib, ...}: let
  # Which nodes belong to which system, for the per-system checks below.
  nodesBySystem = {
    x86_64-linux = ["server"];
    aarch64-darwin = ["macmini"];
  };
in {
  flake.deploy = {
    nodes = {
      # Also deployable from the server itself (agents, or a phone SSH
      # session). deploy-rs always goes over SSH; on the box `server` resolves
      # to its own addresses, so the hop is loopback and the magic-rollback
      # confirm proves sshd survived activation, nothing more. A unit that
      # fails to start still auto-rolls back as usual.
      #
      # No remoteBuild here so that self-deploys build directly. From the
      # macbook pass --remote-build to skip pulling the closure into its store.
      server = {
        hostname = "server";
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
        # macOS /tmp is a symlink to /private/tmp; the magic-rollback watcher
        # sees canary events under the real path and never matches /tmp, so
        # it times out and rolls back a deploy that already activated fine.
        tempPath = "/private/tmp";
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

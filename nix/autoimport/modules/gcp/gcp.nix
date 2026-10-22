# Agent access to the GCP sandbox project: the `cloud-agents` service account,
# Owner of `agent-sandbox-jeanlucthumm` and nothing else. The project's infra is
# plain Terraform in infra/gcp/ at the repo root (bootstrap/ is run by
# Jean-Luc, sandbox/ by agents).
#
# The key is a plain file on the host, not agenix. If the host is wiped, mint
# a new key from a workstation.
#
# Credentials reach agents through the systemd user environment
# (environment.d), which `claude rc` units and every session they spawn
# inherit. rc units are keep-old on switch, so a change lands on their next
# restart.
_: {
  flake.modules.nixos.homeServer = {
    home-manager.users.jeanluc = {
      config,
      pkgs,
      ...
    }: let
      # Kept apart from any personal `gcloud auth login`.
      configDir = "${config.xdg.configHome}/gcloud-sandbox";
      # Service account JSON key, mode 0400. Not managed by nix.
      keyFile = "${configDir}/key.json";
    in {
      home.packages = with pkgs; [
        google-cloud-sdk
        opentofu

        # Google Maps ratings and reviews for agents. Places API is enabled in
        # infra/gcp/sandbox/.
        (writeShellApplication {
          name = "places";
          runtimeInputs = [curl jq google-cloud-sdk];
          text = "places_jq=${./places.jq}\n" + builtins.readFile ./places.sh;
        })
      ];

      systemd.user.sessionVariables = {
        CLOUDSDK_CONFIG = configDir;
        CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE = keyFile;
        CLOUDSDK_CORE_PROJECT = "agent-sandbox-jeanlucthumm";
        # Application Default Credentials, for OpenTofu's google provider and
        # client libraries.
        GOOGLE_APPLICATION_CREDENTIALS = keyFile;
      };
    };
  };
}

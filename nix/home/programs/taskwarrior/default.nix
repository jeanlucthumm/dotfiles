# Personal taskwarrior configuration - imports common and adds sync + personal contexts.
{
  config,
  lib,
  ...
}: let
  contextLabels = [
    "cora"
    "cora-validation"
    "cora-mcp"
    "cora-tech"
    "cora-soft"
    "nix"
    "chore"
    "job-anthropic"
  ];
  makeContextEntry = label: let
    projName = builtins.replaceStrings ["-"] ["."] label;
  in {
    ${label} = {
      read = "proj:${projName}";
      write = "proj:${projName}";
    };
  };
in {
  imports = [./common.nix];

  programs.taskwarrior.config = {
    # Sync to GCP. Solutions like Syncthing don't work because its a
    # sqlite DB.
    sync = {
      gcp = {
        bucket = "taskwarrior-23423478";
        credential_path = config.age.secrets.taskwarrior.path;
      };
      encryption_secret = "not-required";
    };
    context = lib.mergeAttrsList (lib.lists.map makeContextEntry contextLabels);
  };
}

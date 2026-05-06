# Personal taskwarrior configuration - imports common and adds sync + personal contexts.
{...}: {
  flake.modules.homeManager.dev = {
    pkgs,
    config,
    lib,
    ...
  }: let
    contextLabels = [
      "nix"
      "chore"
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
    programs.taskwarrior = {
      enable = true;
      dataLocation = config.xdg.dataHome + "/task";
      config = {
        uda = {
          blocks = {
            type = "string";
            label = "Blocks";
          };
          ticket = {
            type = "string";
            label = "Ticket";
          };
        };
        news.version = "3.4.1";
        urgency.uda.priority = {
          H.coefficient = 6.0;
          M.coefficient = 3.9;
          L.coefficient = -1.8;
        };
        hooks.location = config.xdg.configHome + "/task/hooks";
      };
      package = pkgs.taskwarrior3;
      config = {
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
    };
  };
}

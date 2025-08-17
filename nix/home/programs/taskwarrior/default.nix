# Taskwarrior is a cli task tracking tool.
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Contexts in taskwarrior are predefined filters that can be enabled
  # for listing and creating tasks. We define them as a list of labels
  # (allows for `task context <label>`), and then derive the entry in
  # `context` attrs for it.
  contextLabels = [
    "cora"
    "cora-validation"
    "cora-mcp"
    "cora-tech"
    "cora-soft"
    "nix"
    "chore"
  ];
  makeContextEntry = label: let
    # Proj name allows for nesting ('.'), but the label does not.
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
      # Sync to GCP. Solutions like Syncthing don't work because its a
      # sqlite DB.
      sync = {
        gcp = {
          bucket = "taskwarrior-23423478";
          credential_path = config.age.secrets.taskwarrior.path;
        };
        encryption_secret = "not-required";
      };
      # User defined attributes (UDA) are used to add custom fields to tasks.
      uda = {
        # Reverse of `dep:`
        blocks = {
          type = "string";
          label = "Blocks";
        };
        # Ties tasks to ticket/bug tracking system like Notion or Jira.
        ticket = {
          type = "string";
          label = "Ticket";
        };
      };
      news.version = "3.4.1";
      # L isn't low enough by default. The rest are default values.
      urgency.uda.priority = {
        H.coefficient = 6.0;
        M.coefficient = 3.9;
        L.coefficient = -1.8;
      };
      hooks.location = config.xdg.configHome + "/task/hooks";
      # Map labels to attrs and then merge them up into one thing to assign
      # to `context`.
      context = lib.mergeAttrsList (lib.lists.map makeContextEntry contextLabels);
    };
    package = pkgs.taskwarrior3;
  };
}

{
  config,
  pkgs,
  ...
}: let
  contextLabels = [
    "cora"
    "cora-validation"
    "cora-mcp"
    "nix"
    "chore"
  ];
  makeContext = label: let
    projLabel = builtins.replaceStrings ["-"] ["."] label;
  in ''
    context.${label}.read=proj:${projLabel}
    context.${label}.write=proj:${projLabel}
  '';
in {
  # Taskwarrior is a cli task tracking tool.
  programs.taskwarrior = {
    enable = true;
    dataLocation = "${config.xdg.dataHome}/task";
    config = {
      sync = {
        gcp = {
          bucket = "taskwarrior-23423478";
          credential_path = config.age.secrets.taskwarrior.path;
        };
        encryption_secret = "not-required";
      };
    };
    extraConfig =
      ''
        uda.blocks.type=string
        uda.blocks.label=Blocks
        uda.ticket.type=string
        uda.ticket.label=Ticket
        news.version=3.4.1

        urgency.uda.priority.H.coefficient=6.0
        urgency.uda.priority.M.coefficient=3.9
        urgency.uda.priority.L.coefficient=-1.8

        hooks.location=${config.xdg.configHome}/task/hooks

      ''
      + builtins.concatStringsSep "\n" (builtins.map makeContext contextLabels);
    package = pkgs.taskwarrior3;
  };
}

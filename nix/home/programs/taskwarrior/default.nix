{
  config,
  pkgs,
  ...
}: let
  configDir = config.xdg.configHome;
in {
  # Taskwarrior is a cli task tracking tool.
  programs.taskwarrior = {
    enable = true;
    dataLocation = "${config.home.homeDirectory}/Sync/taskwarrior";
    extraConfig = ''
      uda.blocks.type=string
      uda.blocks.label=Blocks
      uda.ticket.type=string
      uda.ticket.label=Ticket
      news.version=3.3.0

      # Put contexts defined with `task context define` in this file
      include ${configDir}/task/context.config
      hooks.location=${configDir}/task/hooks
    '';
    package = pkgs.taskwarrior3;
  };
}

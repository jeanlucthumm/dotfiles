# Workflow-specific dev tools - task tracking, productivity
{pkgs, ...}: {
  home.packages = with pkgs; [
    timewarrior # time tracker
    taskwarrior-enhanced # Enhanced taskwarrior companion CLI
    notion-cli # Notion API CLI
  ];
}

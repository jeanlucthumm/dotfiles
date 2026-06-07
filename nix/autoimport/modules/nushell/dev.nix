# Nushell — dev profile contributions
{
  flake.modules.homeManager.dev = {...}: {
    programs.nushell = {
      shellAliases = {
        t = "task";
        tw = "taskwarrior-enhanced tree";
      };
      extraConfig = builtins.concatStringsSep "\n" [
        (builtins.readFile ./scripts/git.nu)
        (builtins.readFile ./scripts/task.nu)
        (builtins.readFile ./scripts/pr.nu)
        (builtins.readFile ./scripts/parallel.nu)
        (builtins.readFile ./scripts/gh.nu)
        (builtins.readFile ./scripts/notion.nu)
        (builtins.readFile ./scripts/config-dev.nu)
        (builtins.readFile ./scripts/init.nu)
      ];
    };
  };
}

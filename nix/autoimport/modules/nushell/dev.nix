# Nushell — dev profile contributions
{
  flake.modules.homeManager.dev = {...}: {
    programs.nushell = {
      shellAliases = {
        t = "task";
        tw = "taskwarrior-enhanced tree";
      };
      extraConfig = builtins.concatStringsSep "\n" [
        (builtins.readFile ./git.nu)
        (builtins.readFile ./task.nu)
        (builtins.readFile ./pr.nu)
        (builtins.readFile ./parallel.nu)
        (builtins.readFile ./gh.nu)
        (builtins.readFile ./notion.nu)
        (builtins.readFile ./config-dev.nu)
        (builtins.readFile ./init.nu)
      ];
    };
  };
}

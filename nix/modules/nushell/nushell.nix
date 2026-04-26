# Nushell
{...}: {
  flake.modules.homeManager.nushell = {
    config,
    pkgs,
    lib,
    ...
  }: {
    home.packages = [pkgs.nushell];

    programs.nushell = {
      enable = true;
      shellAliases = {
        vim = "nvim";
        fg = "job unfreeze";
      };
      environmentVariables = {
        GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
      };
      settings = {
        completions.algorithm = "fuzzy";
      };
      extraConfig = builtins.readFile ./config-base.nu;
    };
  };
}

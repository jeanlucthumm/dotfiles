# Foundation nushell config - no qol/dev dependencies
{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.nushell = {
    enable = true;
    shellAliases = {
      vim = "nvim";
      fg = "job unfreeze";
    };
    environmentVariables = {
      GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
      EDITOR = ''${pkgs.neovim}/bin/nvim'';
      NH_FLAKE = config.home.homeDirectory + "/nix";
    };
    settings = {
      completions.algorithm = "fuzzy";
    };
    extraConfig = builtins.readFile ./config-foundation.nu;
  };
}

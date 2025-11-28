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
      cd = "z";
      cat = "bat";
      t = "task";
      tw = "taskwarrior-enhanced tree";
      fg = "job unfreeze";
      man = "batman";
    };
    environmentVariables = {
      # For git signing since it spawns gpg in a non-interactive session so gpg
      # doesn't know what tty to display pinentry on.
      GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
      EDITOR = ''${pkgs.neovim}/bin/nvim'';
      # For the nh command to not require flake path
      NH_FLAKE = config.home.homeDirectory + "/nix";
    };
    settings = {
      completions.algorithm = "fuzzy";
    };
    extraConfig = builtins.readFile ./config.nu;
  };
  programs.carapace.enableNushellIntegration = true;
  programs.direnv.enableNushellIntegration = true;
  programs.yazi = {
    shellWrapperName = "y";
    enableNushellIntegration = true;
  };
  programs.zoxide.enableNushellIntegration = true;
}

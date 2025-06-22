{
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
      fg = "job unfreeze";
      y = "yazi";
    };
    environmentVariables = {
      # For git signing since it spawns gpg in a non-interactive session so gpg
      # doesn't know what tty to display pinentry on.
      GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
      EDITOR = ''${pkgs.neovim}/bin/nvim'';
    };
    settings = {
      completions.algorithm = "fuzzy";
    };
    extraConfig = builtins.readFile ./config.nu;
  };
  programs.carapace.enableNushellIntegration = true;
  programs.direnv.enableNushellIntegration = true;
}

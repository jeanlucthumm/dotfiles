{
  config,
  pkgs,
  lib,
  ...
}: let
  homeDir = config.home.homeDirectory;
  configDir = config.xdg.configHome;
in {
  programs.nushell = {
    enable = true;
    shellAliases = {
      vim = "nvim";
      cd = "z";
      nd = "nix develop";
      cat = "bat";
      gt = " git tree";
      gs = " git status";
    };
    configFile.text = builtins.readFile ./config.nu;
    environmentVariables = {
      nix = ''${homeDir}/nix'';
      nixha = ''${homeDir}/nix/home'';
      conf = ''${configDir}'';
      # For git signing since it spawns gpg in a non-interactive session so gpg
      # doesn't know what tty to display pinentry on.
      GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
      SSH_AUTH_SOCK = lib.hm.nushell.mkNushellInline ''$"($env.XDG_RUNTIME_DIR)/ssh-agent"'';
      EDITOR = ''${pkgs.neovim}/bin/nvim'';
    };
  };
  programs.carapace.enableNushellIntegration = true;
}

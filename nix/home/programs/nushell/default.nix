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
      nv = "neovide --fork";
      cd = "z";
      nd = "nix develop";
      cat = "bat";
      t = "task";
    };
    environmentVariables = {
      nix = ''${homeDir}/nix'';
      nixha = ''${homeDir}/nix/home'';
      conf = ''${configDir}'';
      # For git signing since it spawns gpg in a non-interactive session so gpg
      # doesn't know what tty to display pinentry on.
      GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
      EDITOR = ''${pkgs.neovim}/bin/nvim'';
    };
    extraConfig = builtins.readFile ./config.nu;
    extraEnv = builtins.readFile ./env.nu;
  };
  programs.carapace.enableNushellIntegration = true;
}

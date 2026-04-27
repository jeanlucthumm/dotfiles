# Nushell — cli profile contributions
{
  flake.modules.darwin.cli = {
    # Allow nushell as a login shell. Installed via home-manager, so it lives
    # under the per-user profile path.
    environment.shells = ["/etc/profiles/per-user/jeanluc/bin/nu"];
  };

  flake.modules.homeManager.cli = {
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
        cd = "z";
        cat = "bat";
        man = "batman";
      };
      environmentVariables = {
        GPG_TTY = lib.hm.nushell.mkNushellInline "^tty";
      };
      settings = {
        completions.algorithm = "fuzzy";
      };
      extraConfig = builtins.concatStringsSep "\n" [
        (builtins.readFile ./config-base.nu)
        (builtins.readFile ./config-qol.nu)
      ];
    };

    # Custom integration in config-qol.nu with path fallback
    programs.carapace.enableNushellIntegration = false;
    programs.direnv.enableNushellIntegration = true;
    programs.yazi = {
      shellWrapperName = "y";
      enableNushellIntegration = true;
    };
    programs.zoxide.enableNushellIntegration = true;
  };
}

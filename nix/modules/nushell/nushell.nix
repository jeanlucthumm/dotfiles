# Nushell
{...}: {
  flake.modules.darwin.nushell = {
    # Ensure nushell is an allowed login shell in /etc/shells
    # Note: nushell is installed via home-manager, so we use the per-user profile path
    environment.shells = ["/etc/profiles/per-user/jeanluc/bin/nu"];
  };

  flake.modules.homeManager.nushell = {
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


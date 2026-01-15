# QoL nushell config - depends on qol packages (eza, bat, zoxide, fzf, etc.)
{pkgs, ...}: {
  programs.nushell = {
    shellAliases = {
      cd = "z";
      cat = "bat";
      man = "batman";
    };
    extraConfig = builtins.readFile ./config-qol.nu;
  };
  programs.carapace.enableNushellIntegration = false; # Custom integration in config-qol.nu with path fallback
  programs.direnv.enableNushellIntegration = true;
  programs.yazi = {
    shellWrapperName = "y";
    enableNushellIntegration = true;
  };
  programs.zoxide.enableNushellIntegration = true;
}

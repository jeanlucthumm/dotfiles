{...}: {
  programs.nushell.extraConfig = builtins.readFile ./nixos-config.nu;
}

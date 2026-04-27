# Nushell — nixos homeManager contributions
{
  flake.modules.homeManager.nixos = {...}: {
    programs.nushell.extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./nixos-config.nu)
      ''
        # TODO: switch back to nh once tty passthrough is fixed (~/code/nh/issue.md)
        def nrs []: [nothing -> nothing] {
            sudo nixos-rebuild switch --flake ~/nix
        }

        def nra []: [nothing -> nothing] {
            sudo nixos-rebuild switch --flake ~/nix --upgrade
        }
      ''
    ];
  };
}

# Foundational settings for NixOS.
{...}: {
  programs = {
    nushell.configFile.text = ''
      # TODO: switch back to nh once TTY passthrough is fixed (~/Code/nh/ISSUE.md)
      def nrs []: [nothing -> nothing] {
          sudo nixos-rebuild switch --flake ~/nix
      }

      def nra []: [nothing -> nothing] {
          sudo nixos-rebuild switch --flake ~/nix --upgrade
      }
    '';
  };
}

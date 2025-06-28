# Foundational settings for NixOS.
{...}: {
  programs = {
    nushell.configFile.text = ''
      def nrs []: [nothing -> nothing] {
          nh os switch
      }

      def nra []: [nothing -> nothing] {
          nh os switch -u
      }
    '';
  };
}

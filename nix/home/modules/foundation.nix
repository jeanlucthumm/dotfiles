# System agnostic foundational settings.
{hostName, ...}: {
  programs = {
    fish.shellAliases = {
      nsys = "cd $HOME/nix && $EDITOR ./system/hosts/${hostName}.nix";
      nhome = "cd $HOME/nix && $EDITOR ./home/hosts/${hostName}.nix";
    };
    nushell.configFile.text = ''
      def --env nsys []: [nothing -> nothing] {
          cd ([$env.HOME nix] | path join)
          ^$env.EDITOR "./system/hosts/${hostName}/default.nix"
      }
      def --env nhome []: [nothing -> nothing] {
          cd ([$env.HOME nix] | path join)
          ^$env.EDITOR "./home/hosts/${hostName}.nix"
      }
    '';
  };
}

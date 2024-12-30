# Foundation settings for Darwin.
{hostName, ...}: {
  programs = {
    fish.shellAliases.nrs = "nix run nix-darwin -- switch --flake $HOME/nix#${hostName}";
    nushell.configFile.text = ''
      def nrs []: [nothing -> nothing] {
        nix run nix-darwin -- switch --flake $HOME/nix#${hostName}
      }
    '';
  };

  home.sessionVariables = {
    OS = "Darwin";

    # Extra stuff to add to $PATH
    sessionPath = [
      # homebrew puts all its stuff in this directory instead
      # of /usr/bin or otherwise
      "/opt/homebrew/bin"
    ];
  };
}

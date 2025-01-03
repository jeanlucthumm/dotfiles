# Foundation settings for Darwin.
{
  config,
  hostName,
  ...
}: {
  programs = {
    fish.shellAliases.nrs = "nix run nix-darwin -- switch --flake $HOME/nix#${hostName}";
    nushell.configFile.text = ''
      def nrs []: [nothing -> nothing] {
        let flake = "$($env.HOME)/nix#${hostName}"
        nix run nix-darwin -- switch --flake $flake
      }
    '';
  };

  home = {
    sessionVariables = {
      OS = "Darwin";
    };

    # Extra stuff to add to $PATH
    sessionPath = [
      # homebrew puts all its stuff in this directory instead
      # of /usr/bin or otherwise
      "/opt/homebrew/bin"
      # Any Dart dev requires this in path
      "${config.home.homeDirectory}/.pub-cache/bin"
    ];
  };
}

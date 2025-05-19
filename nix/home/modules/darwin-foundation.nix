# Foundation settings for Darwin.
{
  config,
  pkgs,
  hostName,
  ...
}: {
  programs = {
    fish.shellAliases.nrs = "nix run nix-darwin -- switch --flake $HOME/nix#${hostName}";
    nushell.configFile.text = ''
      def nrs []: [nothing -> nothing] {
        let flake = $"($env.HOME)/nix#${hostName}"
        sudo nix run nix-darwin -- switch --flake $flake
      }
    '';

    # Since we don't use Flutter with nix, we have to globally enable related programs.
    rbenv = {
      enable = true;
      enableFishIntegration = true;
      plugins = [
        {
          name = "ruby-build";
          src = pkgs.fetchFromGitHub {
            owner = "rbenv";
            repo = "ruby-build";
            rev = "b5ade6192cb39d1c6d70686521493d17d122b62b";
            hash = "sha256-3Maw4OktBaiTH/W199GkzxVXtLpQeXU48mCLvOXt0Vg=";
          };
        }
      ];
    };
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

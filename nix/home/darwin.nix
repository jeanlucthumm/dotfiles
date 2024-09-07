{
  config,
  pkgs,
  lib,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  imports = [
    ./modules/common.nix
    ./modules/darwin-fish-fix.nix
  ];

  home = {
    sessionVariables = {
      OS = "Darwin";
      ANDROID_HOME = "/Users/${config.home.username}/Library/Android/sdk";
    };

    # Extra stuff to add to $PATH
    sessionPath = [
      # homebrew puts all its stuff in this directory instead
      # of /usr/bin or otherwise
      "/opt/homebrew/bin"
    ];
  };

  home.file = {
    # gpgagent not yet supported for darwin
    "${homeDir}/.gnupg/gpg-agent.conf".text = ''
      pinentry-program ${pkgs.pinentry-tty}/bin/pinentry-tty
      # In seconds
      default-cache-ttl ${toString (4 * 60 * 60)}
      max-cache-ttl ${toString (4 * 60 * 60)}
    '';
  };
}

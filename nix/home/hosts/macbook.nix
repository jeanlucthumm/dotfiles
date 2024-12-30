{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  imports = [
    ../modules/darwin-foundation.nix
    ../modules/cli.nix
    ../modules/darwin-fish-fix.nix
  ];

  home.file = {
    # gpgagent not yet supported for darwin
    "${homeDir}/.gnupg/gpg-agent.conf".text = ''
      pinentry-program ${pkgs.pinentry-tty}/bin/pinentry-tty
      # In seconds
      default-cache-ttl ${toString (4 * 60 * 60)}
      max-cache-ttl ${toString (4 * 60 * 60)}
    '';
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}

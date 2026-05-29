fp: let
  user = "jeanluc";
in {
  flake.modules.nixos.base = {
    config,
    pkgs,
    ...
  }: {
    users.users.jeanluc = {
      isNormalUser = true;
      description = "Jean-Luc Thumm";
      extraGroups = [
        "networkmanager"
        "wheel"
        # Android Debug Bridge unprivileged access
        "adbusers"
        # Docker without sudo
        "docker"
        # Access to storage devices and related functionality
        "storage"
      ];
      shell = pkgs.nushell;
      # TODO use hashedPasswordFile
    };

    # Allows jeanluc additional rights when connecting to the daemon, like managing caches.
    # This is useful for devenv.
    nix.settings.trusted-users = [user];
  };

  flake.modules.darwin.base = {
    users.users.${user} = {
      name = user;
      home = "/Users/${user}";
    };
  };
}

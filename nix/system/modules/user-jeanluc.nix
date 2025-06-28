{
  pkgs,
  config,
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
    openssh.authorizedKeys.keys = [
      # Desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP66W+zH1wVKLB/fXdWF5VIHR5ggphdRMtWzd26uL7I3"
    ];
  };

  # Allows agenix to use user ssh keys
  age.identityPaths = [
    "${config.users.users.jeanluc.home}/.ssh/id_ed25519"
  ];

  # Allows jeanluc additional rights when connecting to the daemon, like managing caches.
  # This is useful for devenv.
  nix.settings.trusted-users = ["jeanluc"];
}

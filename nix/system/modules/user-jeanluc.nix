{pkgs, ...}: {
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
    ];
    shell = pkgs.nushell;
  };

  # Allows jeanluc additional rights when connecting to the daemon, like managing caches.
  # This is useful for devenv.
  nix.settings.trusted-users = ["jeanluc"];
}

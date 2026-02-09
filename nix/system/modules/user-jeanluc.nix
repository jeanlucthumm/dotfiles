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
    openssh.authorizedKeys.keys = (import ../../secrets/pubkeys.nix).all;
    hashedPassword = "$y$j9T$olPxnw3sjt6/HFw.1SKyT/$GVqznhguvSLErdAQxNW0O6CKxVuUc6trVrxvj2pJLw1";
  };

  # age.identityPaths set per-host (YubiKey identity for desktop, SSH for server)

  # Allows jeanluc additional rights when connecting to the daemon, like managing caches.
  # This is useful for devenv.
  nix.settings.trusted-users = ["jeanluc"];
}

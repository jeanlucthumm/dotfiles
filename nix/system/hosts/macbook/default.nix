{...}: {
  imports = [
    ./theme-setting.nix
  ];
  nix = {
    enable = true;
    settings = {
      experimental-features = "nix-command flakes";
      # Allows jeanluc additional rights when connecting to the daemon, like managing caches.
      # This is useful for devenv.
      trusted-users = ["jeanluc"];
    };
  };

  # System level fish config so that we get access to nix commands
  programs = {
    fish.enable = true;
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  system.primaryUser = "jeanluc";

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jeanluc = {
    name = "jeanluc";
    home = "/Users/jeanluc";
  };

  # Allows home manager modules to access theme
  home-manager.sharedModules = [./theme-setting.nix];
}

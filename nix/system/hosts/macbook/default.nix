{...}: {
  imports = [
    ./theme-setting.nix
  ];
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix.settings.experimental-features = "nix-command flakes";

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

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jeanluc = {
    name = "jeanluc";
    home = "/Users/jeanluc";
  };

  home-manager.sharedModules = [./theme-setting.nix];
}

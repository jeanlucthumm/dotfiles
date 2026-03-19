{pkgs, ...}: {
  imports = [
    ../../modules/darwin/foundation.nix
    ./theme-setting.nix
  ];

  # Determinate Nix manages nix settings
  nix.enable = false;

  environment.systemPackages = with pkgs; [
  ];

  stylix.homeManagerIntegration.followSystem = false;
  stylix.enableReleaseChecks = false;

  system.stateVersion = 4;
  system.primaryUser = "jeanlucthumm";

  ids.gids.nixbld = 350;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jeanlucthumm = {
    name = "jeanlucthumm";
    home = "/Users/jeanlucthumm";
  };

  environment.shells = ["/etc/profiles/per-user/jeanlucthumm/bin/nu"];

  home-manager.sharedModules = [./theme-setting.nix];
}

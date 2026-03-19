{pkgs, ...}: {
  imports = [
    ./theme-setting.nix
  ];

  nix = {
    enable = false;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = ["jeanlucthumm"];
    };
  };

  environment.systemPackages = with pkgs; [
    podman
    (writeShellScriptBin "docker" ''
      #!/usr/bin/env bash
      exec ${pkgs.podman}/bin/podman "$@"
    '')
    podman-compose
    qemu
    podman-tui
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

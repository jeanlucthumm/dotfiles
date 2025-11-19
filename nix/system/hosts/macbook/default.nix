{pkgs, ...}: let
  pubkeys = import ../../../secrets/pubkeys.nix;
in {
  imports = [
    ../../modules/agenix.nix
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
    gnupg.agent.enable = true;
  };

  # SSH server configuration
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
    '';
  };

  environment.systemPackages = with pkgs; [
    raycast # Spotlight replacement
    podman
    (writeShellScriptBin "docker" ''
      #!/usr/bin/env bash
      exec ${pkgs.podman}/bin/podman "$@"
    '') # docker CLI shim that forwards to podman
    podman-compose
    qemu
    podman-tui
  ];

  stylix.homeManagerIntegration.followSystem = false;

  # Optional: launchd agent to auto-start the podman machine (kept commented per request)
  # launchd.user.agents.podman-machine-default = {
  #   enable = true;
  #   program = "${pkgs.podman}/bin/podman";
  #   programArguments = ["machine" "start" "podman-machine-default"];
  #   keepAlive = true;
  #   runAtLoad = true;
  #   standardOutPath = "/tmp/podman-machine.log";
  #   standardErrorPath = "/tmp/podman-machine.err";
  # };

  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Disable Spotlight search (Cmd+Space)
        "64".enabled = false;
        # Disable Finder search window (Cmd+Option+Space)
        "65".enabled = false;
        "34" = {
          # Show application windows (Ctrl+Down)
          enabled = true;
          value = {
            parameters = [65535 125 2359296];
            type = "standard";
          };
        };
        "27" = {
          # Move focus to next window (Cmd+`)
          enabled = true;
          value = {
            parameters = [96 50 1048576];
            type = "standard";
          };
        };
      };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  system.primaryUser = "jeanluc";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jeanluc = {
    name = "jeanluc";
    home = "/Users/jeanluc";
    openssh.authorizedKeys.keys = [
      pubkeys.desktop
      pubkeys.phone
      pubkeys.server
    ];
  };

  # Ensure nushell is an allowed login shell in /etc/shells
  environment.shells = [pkgs.nushell "/opt/homebrew/bin/fish"];

  # Allows home manager modules to access theme
  home-manager.sharedModules = [./theme-setting.nix];
}

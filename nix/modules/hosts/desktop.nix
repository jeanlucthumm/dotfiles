fp: {
  flake.nixosConfigurations."desktop" = fp.inputs.nixpkgs.lib.nixosSystem {
    modules = with fp.config.flake.modules.nixos; [
      base
      dev
      graphical
      secrets
      theme
      amdGpu
      {
        networking.hostName = "desktop";
        networking.hostId = "17646629";
        jl.system = "x86_64-linux";
        theme = fp.jlib.withLocalThemeOverride {
          name = "gruvbox";
          darkMode = false;
          fontCoding = {
            name = "JetBrainsMono Nerd Font Mono";
            size = 10;
            package = pkgs.nerd-fonts.jetbrains-mono;
          };
        };
        age = {
          identityPaths = [
            ./_host-specific/desktop/yubikey-identity.txt
          ];
        };
        # Block distracting websites
        networking.extraHosts = ''
          127.0.0.1 chess.com
          127.0.0.1 www.chess.com
          127.0.0.1 lichess.org
          127.0.0.1 www.lichess.org
        '';
        swapDevices = [
          {
            device = "/swapfile";
            size = 32 * 1024; # 32 GiB
          }
        ];
        # Software that runs in the background
        services = {
          # Schedule tasks to run at specific times using `at` command
          atd = {
            enable = true;
            allowEveryone = true;
          };
        };
        # This is a systemd service that delays system boot until network connectivity is established.
        # Disabling speeds up boot time, but need to make sure nothing requires immediate network
        # connectivity
        systemd.services.NetworkManager-wait-online.enable = false;
        system.stateVersion = "24.05";
      }
    ];
  };
}

fp @ {jlib, ...}: {
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
        theme = jlib.withLocalThemeOverride {
          name = "gruvbox";
          darkMode = false;
          fontCoding = {
            name = "JetBrainsMono Nerd Font Mono";
            size = 10;
            package = pkgs.nerd-fonts.jetbrains-mono;
          };
        };

        # TODO: let's just create per fp module options, e.g. `fpmodule.secrets.idPath`
        age.identityPaths = [
          ./_host-specific/desktop/yubikey-identity.txt
        ];

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

        home-manager.users.jeanluc = {
          imports = [fp.config.flake.modules.generic.monitor];

          age.identityPaths = [
            ./_host-specific/desktop/yubikey-identity.txt
          ];
          home.stateVersion = "24.05";

          monitors.primary = {
            manufacturer = "Shenzhen KTC Technology Group";
            model = "M32P10";
            serial = "0000000000001";
            width = 3840;
            height = 2160;
            refresh = 144.0;
            rotation = 0;
            position_x = 0;
            position_y = 0;
          };

          monitors.secondary = {
            manufacturer = "PNP(AOC)";
            model = "U2790B";
            serial = "0x00029BC0";
            width = 3840;
            height = 2160;
            refresh = 60.0;
            rotation = 270;
            position_x = 3840;
            position_y = -900;
          };
        };
      }
    ];
  };
}

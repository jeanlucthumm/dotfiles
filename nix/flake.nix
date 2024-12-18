{
  description = "Jean-Luc Thumm normal systems configuration";

  # Pin nixpkgs for every imput to avoid multiple evaluations.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    stylix,
    nix-darwin,
    zen-browser,
    ...
  }: let
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # System configurations for NixOS hosts.
    nixosConfigurations = {
      "laptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jeanluc = import ./home/linux.nix;
          }
        ];
      };

      "desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit zen-browser;};
        modules = [
          stylix.nixosModules.stylix
          ./hosts/theme-setting.nix
          ./hosts/desktop
          ({
            config,
            zen-browser,
            ...
          }: {
            environment.systemPackages = [
              zen-browser.packages.${config.nixpkgs.system}.specific
            ];
          })
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs.hostName = "desktop";
            home-manager.users.jeanluc = {...}: {
              imports = [
                ./home/linux.nix
                ./hosts/desktop/theme-setting.nix
              ];
            };
          }
        ];
      };

      # System configuration for VM.
      # Do:
      #   nixos-rebuild build-vm --flake .#virtual
      #   ./result/bin/run-virtual-vm
      #
      # If you're not on NixOS then:
      #   nix run .#virtual-vm
      # That works because of the `packages` attr below.
      "virtual" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit nixpkgs;};
        modules = [
          stylix.nixosModules.stylix
          ./hosts/theme-setting.nix
          ./hosts/virtual
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs.hostName = "virtual";
            home-manager.users.jeanluc = {...}: {
              imports = [./home/linux.nix ./hosts/virtual/theme-setting.nix];
            };
          }
        ];
      };
    };

    # System configurations for Darwin hosts.
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/macbook/configuration.nix
        # The system module tree is different than the Home Manager one,
        # so we import theme settings in both to ensure they're available.
        ./hosts/macbook/theme-setting.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs.hostName = "macbook";
          home-manager.users.jeanluc = {...}: {
            imports = [./home/darwin.nix ./hosts/macbook/theme-setting.nix];
          };
        }
      ];
    };

    # Development environment to work on this flake.
    # Since the format is `devShells.<system>.<shell_name>`, we generate the same
    # attrs for each default system.
    devShells = forAllSystems (
      system:
      # Recommended way to access nixpkgs for a specific system.
      # Otherwise need to call nixpkgs with a specific system param.
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            statix
            alejandra
            manix
          ];

          shellHook = ''
            # Enter shell to the same one user is using, otherwise it would
            # just open bash. Note you have to exit twice to leave the shell.
            exec $SHELL
          '';
        };
      }
    );

    packages = forAllSystems (
      system: {
        virtual-vm = self.nixosConfigurations.virtual.config.system.build.vm;
      }
    );
  };
}

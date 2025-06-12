{
  description = "Jean-Luc Thumm normal systems configuration";

  # Pin nixpkgs for every imput to avoid multiple evaluations.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
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
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    agenix,
    home-manager,
    stylix,
    nix-darwin,
    zen-browser,
    ...
  }: {
    # System configurations for NixOS hosts.
    nixosConfigurations = {
      "desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          ./system/hosts/desktop
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs.hostName = "desktop";
            home-manager.users.jeanluc = import ./home/hosts/desktop.nix;
            home-manager.sharedModules = [agenix.homeManagerModules.default];
          }
        ];
      };

      # System configuration for my server.
      # This is headless 24/7 system.
      "server" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          ./system/hosts/server
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs.hostName = "server";
            home-manager.users.jeanluc = import ./home/hosts/server.nix;
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
        specialArgs = {
          inherit inputs;
        };
        modules = [
          stylix.nixosModules.stylix
          ./system/hosts/theme-setting.nix
          ./system/hosts/virtual
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs.hostName = "virtual";
            home-manager.users.jeanluc = {...}: {
              imports = [./home/linux.nix ./hosts/virtual/theme-setting.nix];
            };
          }
        ];
      };
    };

    # nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake '.#macbook'

    # System configurations for Darwin hosts.
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules = [
        stylix.darwinModules.stylix
        home-manager.darwinModules.home-manager
        agenix.darwinModules.default
        ./system/hosts/macbook
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs.hostName = "macbook";
          home-manager.users.jeanluc = import ./home/hosts/macbook.nix;
          home-manager.sharedModules = [agenix.homeManagerModules.default];
        }
      ];
    };

    packages = let
      vm = self.nixosConfigurations.virtual.config.system.build.vm;
    in {
      # NixOS VM is only available on Linux.
      "aarch64-linux".virtual-vm = vm;
      "x86_64-linux".virtual-vm = vm;
    };
  };
}

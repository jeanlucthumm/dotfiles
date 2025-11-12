{
  description = "Jean-Luc Thumm normal systems configuration";

  # Pin nixpkgs for every imput to avoid multiple evaluations.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    reddit-easy-post = {
      url = "github:jeanlucthumm/reddit-easy-post";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    taskwarrior-enhanced = {
      url = "github:jeanlucthumm/taskwarrior-enhanced";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For making python overlays.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    agenix,
    home-manager,
    stylix,
    nix-darwin,
    zen-browser,
    niri,
    disko,
    deploy-rs,
    reddit-easy-post,
    taskwarrior-enhanced,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    ...
  }: {
    # System configurations for NixOS hosts.
    nixosConfigurations = {
      "desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          niri.nixosModules.niri
          ./system/modules/home-manager.nix
          ./system/hosts/desktop
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              hostName = "desktop";
            };
            home-manager.users.jeanluc = import ./home/hosts/desktop.nix;
            nixpkgs.overlays = import ./overlays inputs;
          }
        ];
      };

      # System configuration for my server.
      # This is a headless 24/7 system.
      "server" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          disko.nixosModules.disko
          ./system/modules/home-manager.nix
          ./system/hosts/server
          {
            home-manager.extraSpecialArgs.hostName = "server";
            home-manager.users.jeanluc = import ./home/hosts/server.nix;
            nixpkgs.overlays = import ./overlays inputs;
          }
        ];
      };

      # Custom live installer ISO with SSH keys pre-configured
      "iso" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./system/hosts/iso.nix
        ];
      };
    };

    # System configurations for Darwin hosts.
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules = [
        stylix.darwinModules.stylix
        home-manager.darwinModules.home-manager
        agenix.darwinModules.default
        ./system/modules/home-manager.nix
        ./system/hosts/macbook
        {
          home-manager.extraSpecialArgs.hostName = "macbook";
          home-manager.users.jeanluc = import ./home/hosts/macbook.nix;
          nixpkgs.overlays = import ./overlays inputs;
        }
      ];
    };

    deploy.nodes.server = {
      hostname = "server.lan";
      sshUser = "jeanluc";
      user = "root";
      # wheel group has passwordless sudo on server, so interactive sudo prompts are unnecessary
      interactiveSudo = false;
      profiles.system = {
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.server;
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    templates = {
      python = {
        path = ./templates/python;
        description = "Python development environment using devenv";
      };
    };
  };
}

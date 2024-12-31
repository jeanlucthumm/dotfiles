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
    };
    maptheme = {
      url = "path:/Users/jeanluc/Code/nix-maptheme";
    };
    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    base16.url = "github:SenchoPens/base16.nix";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    stylix,
    nix-darwin,
    zen-browser,
    maptheme,
    tt-schemes,
    base16,
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
    colors = forAllSystems (
      system: let
        base16lib = base16.lib {inherit (nixpkgs.legacyPackages.${system}) pkgs lib;};
      in {
        nord = base16lib.mkSchemeAttrs "${tt-schemes}/base16/nord.yaml";
        solarized-light = base16lib.mkSchemeAttrs "${tt-schemes}/base16/solarized-light.yaml";
      }
    );
  in {
    # System configurations for NixOS hosts.
    nixosConfigurations = {
      "desktop" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit zen-browser tt-schemes;
          colors = colors.${system};
        };
        modules = [
          stylix.nixosModules.stylix
          maptheme.nixosModules.maptheme
          ({config, ...}: {
            maptheme.console = {
              enable = true;
              colors = colors.${system}.nord;
            };
          })
          ./system/hosts/desktop
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs.hostName = "desktop";
            home-manager.users.jeanluc = import ./home/hosts/desktop.nix;
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

    # nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake '.#macbook'

    # System configurations for Darwin hosts.
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [
        ./system/hosts/macbook
        home-manager.darwinModules.home-manager
        maptheme.darwinModules.maptheme
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            hostName = "macbook";
            colors = colors.aarch64-darwin;
          };
          home-manager.users.jeanluc = import ./home/hosts/macbook.nix;
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
            # just open bash. Also exit with correct status when we're done.
            bash -c "$SHELL"; exit $?
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

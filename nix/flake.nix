{
  description = "Jean-Luc Thumm normal systems configuration";

  # Default to pinning nixpkgs to one version to avoid evaluating multiple
  # versions.
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
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    stylix,
    darwin,
    ...
  } @ inputs: let
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
    nixosConfigurations."laptop" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.jeanluc = import ./home;
        }
      ];
    };
    darwinConfigurations."macbook" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./theme.nix
        ./theme-setting.nix
        ./hosts/macbook/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.jeanluc = {
            config,
            pkgs,
            ...
          }: {
            imports = [./home];
            _module.args.theme = config.theme;
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
          ];
        };
      }
    );
  };
}

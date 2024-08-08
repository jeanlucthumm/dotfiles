{
  description = "NixOS configuration";

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
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    home-manager,
    stylix,
    darwin,
    ...
  }: {
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
  };
}

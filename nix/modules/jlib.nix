# Custom library functions
{lib, ...}: {
  flake.modules.generic.jlib = {
    # Creates per system home manager config
    mkHomeManager = pkgs: {
      generic ? null,
      darwin ? null,
      nixos ? null,
    }:
      lib.mkMerge [
        (lib.mkIf (generic != null) generic)
        (lib.mkIf (darwin != null && pkgs.hostPlatform.isDarwin) darwin)
        (lib.mkIf (nixos != null && pkgs.hostPlatform.isLinux) nixos)
      ];
    mkHomeManagerNixOS = pkgs: nixos:
      lib.mkIf pkgs.hostPlatform.isLinux nixos;
  };
}

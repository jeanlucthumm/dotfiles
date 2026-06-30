# LLM / AI tooling
fp @ {
  jlib,
  withSystem,
  ...
}: {
  flake.modules.homeManager.dev = let
    mkFpkgs = system: withSystem system ({config, ...}: config.packages);
  in
    jlib.mkHomeManager {
      generic = {
        pkgs,
        lib,
        system,
        ...
      }: {
        home.packages = [
          # Way more up to date than nixpkgs
          fp.inputs.claude-code.packages.${system}.claude-code

          pkgs.opencode # AI coding agent TUI
        ];

        programs = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
          codex.enable = true;
        };
      };

      nixos = {system, ...}: let
        fpkgs = mkFpkgs system;
      in {
        home.packages = [
          fpkgs.reddit-mcp-server
        ];
      };
    };
}

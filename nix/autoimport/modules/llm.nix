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
        # # Only ships darwin-arm64 builds for now
        # ++ lib.optionals (system == "aarch64-darwin") [
        #   fp.inputs.terminal-browser.packages.${system}.default
        # ];
      };

      darwin = {system, ...}: {
        home.packages = [
          fp.inputs.terminal-browser.packages.${system}.default
        ];
      };

      nixos = {
        lib,
        pkgs,
        system,
        ...
      }: let
        fpkgs = mkFpkgs system;
      in {
        home.packages = [
          fpkgs.reddit-mcp-server
        ];

        programs = {
          codex.enable = true;
        };
      };
    };
}

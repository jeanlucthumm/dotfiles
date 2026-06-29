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
      }: let
        fpkgs = mkFpkgs system;
      in {
        home.packages = [
          fpkgs.mcp-flutter # MCP server for Flutter app debugging
          fpkgs.mcp-language-server # MCP server that exposes language servers to LLMs
          fpkgs.mcp-opennutrition # OpenNutrition dataset MCP server

          # Way more up to date than nixpkgs
          fp.inputs.claude-code.packages.${system}.claude-code

          pkgs.aichat # AI chatbot for the terminal
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

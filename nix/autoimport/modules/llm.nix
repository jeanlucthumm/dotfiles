# LLM / AI tooling
fp: {
  flake.modules.homeManager.dev = {
    pkgs,
    lib,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
    fpkgs = fp.withSystem system ({config, ...}: config.packages);
  in
    fp.jlib.mkHomeManager pkgs {
      generic = {
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

      nixos = {
        home.packages = [
          fpkgs.mcp-reddit
        ];
      };
    };
}

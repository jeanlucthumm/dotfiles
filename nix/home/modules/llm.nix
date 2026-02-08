# Everything related to AI
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      aichat # AI chatbot for the terminal
      mcp-flutter # MCP server for Flutter app debugging
      mcp-language-server # MCP server that exposes language servers to LLMs
      mcp-opennutrition # OpenNutrition dataset MCP server
      claude-code # CLI LLM coding utility
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      # MCP Servers (see nix/overlays directory)
      graphiti-mcp-server # Knowledge graph MCP server
      mcp-reddit # MCP server for Reddit data
    ];

  programs = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    codex.enable = true;
  };
}

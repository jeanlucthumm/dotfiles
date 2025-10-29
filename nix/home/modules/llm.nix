# Everything related to AI
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      claude-code # CLI LLM coding utility
      aichat # AI chatbot for the terminal
      mcp-language-server # MCP server that exposes language servers to LLMs
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      # TODO: mcp-nixos has build issues on Darwin, exclude for now
      mcp-nixos # MCP server for NixOS packages and configuration

      # MCP Servers (see nix/overlays directory)
      mcp-opennutrition # OpenNutrition dataset MCP server
      graphiti-mcp-server # Knowledge graph MCP server
      mcp-reddit # MCP server for Reddit data
    ];
}

# Everything related to AI
{pkgs, ...}: {
  home.packages = with pkgs; [
    claude-code # CLI LLM coding utility
    aichat # AI chatbot for the terminal

    # MCP Servers (see nix/overlays directory)
    mcp-opennutrition # OpenNutrition dataset MCP server
    mcp-language-server # MCP server that exposes language servers to LLMs
    graphiti-mcp-server # Knowledge graph MCP server
  ];
}

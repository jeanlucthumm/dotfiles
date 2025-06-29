# Everything related to AI
{pkgs, ...}: {
  home.packages = with pkgs; [
    claude-code # CLI LLM coding utility
    aichat # AI chatbot for the terminal

    # Overlays (see nix/overlays directory)
    mcp-opennutrition
  ];
}

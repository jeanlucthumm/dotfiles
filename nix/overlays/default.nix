inputs: [
  (final: prev: {
    mcp-opennutrition = prev.callPackage ./mcp-opennutrition.nix {};
    mcp-language-server = prev.callPackage ./mcp-language-server.nix {};
    graphiti-mcp-server = prev.callPackage ./graphiti-mcp-server.nix {
      inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
    };
    mcp-reddit = prev.callPackage ./mcp-reddit.nix {
      inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
    };
  })
  (final: prev: {
    reddit-easy-post = inputs.reddit-easy-post.packages.${prev.system}.default;
    taskwarrior-enhanced = inputs.taskwarrior-enhanced.packages.${prev.system}.default;
  })
]

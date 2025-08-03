inputs: [
  (final: prev: {
    mcp-opennutrition = prev.callPackage ./mcp-opennutrition.nix {};
    graphiti-mcp-server = prev.callPackage ./graphiti-mcp-server.nix {
      inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
    };
  })
  (final: prev: {
    reddit-easy-post = inputs.reddit-easy-post.packages.${prev.system}.default;
  })
]

inputs: [
  (final: prev: {
    mcp-opennutrition = prev.callPackage ./mcp-opennutrition.nix {};
  })
  (final: prev: {
    reddit-easy-post = inputs.reddit-easy-post.packages.${prev.system}.default;
  })
]

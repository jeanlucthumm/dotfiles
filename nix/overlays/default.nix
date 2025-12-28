inputs: [
  (final: prev: {
    difit = prev.callPackage ./difit.nix {};
    mcp-opennutrition = prev.callPackage ./mcp-opennutrition.nix {};
    mcp-language-server = prev.callPackage ./mcp-language-server.nix {};
    graphiti-mcp-server = prev.callPackage ./graphiti-mcp-server.nix {
      inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
    };
    mcp-reddit = prev.callPackage ./mcp-reddit.nix {
      inherit (inputs) uv2nix pyproject-nix pyproject-build-systems;
    };
    notify = prev.callPackage ./notify.nix {};
    notion-cli = prev.callPackage ./notion-cli.nix {};
  })
  (final: prev: {
    reddit-easy-post = inputs.reddit-easy-post.packages.${prev.stdenv.hostPlatform.system}.default;
    taskwarrior-enhanced = inputs.taskwarrior-enhanced.packages.${prev.stdenv.hostPlatform.system}.default;
  })
]

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
    mcp-flutter = prev.callPackage ./mcp-flutter.nix {};
    notify = prev.callPackage ./notify.nix {};
    notion-cli = prev.callPackage ./notion-cli.nix {};
  })
  (final: prev: {
    reddit-easy-post = inputs.reddit-easy-post.packages.${prev.stdenv.hostPlatform.system}.default;
    taskwarrior-enhanced = inputs.taskwarrior-enhanced.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  inputs.nix-openclaw.overlays.default
  inputs.claude-code.overlays.default
  # TODO: Remove once devenv 2.0.4 lands in nixpkgs (fixes Boehm GC crash on macOS)
  (final: prev: {
    devenv = inputs.devenv-src.packages.${prev.stdenv.hostPlatform.system}.devenv;
  })
]

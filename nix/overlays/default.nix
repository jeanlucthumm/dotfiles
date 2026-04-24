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
    mcp-flutter = prev.callPackage ./mcp-flutter.nix {};
    notify = prev.callPackage ./notify.nix {};
    notion-cli = prev.callPackage ./notion-cli.nix {};
  })
  (final: prev: {
    reddit-easy-post = inputs.reddit-easy-post.packages.${prev.stdenv.hostPlatform.system}.default;
    taskwarrior-enhanced = inputs.taskwarrior-enhanced.packages.${prev.stdenv.hostPlatform.system}.default;
  })
  # Extend pkgs.sem (Semaphore CI CLI) to Darwin — upstream is pure Go and
  # ships Darwin arm64 binaries, but the nixpkgs meta restricts it to Linux.
  (final: prev: {
    sem = prev.sem.overrideAttrs (old: {
      meta = old.meta // {
        platforms = old.meta.platforms ++ prev.lib.platforms.darwin;
      };
    });
  })
  # Temporary: pull nushell from a pinned nixpkgs with the darwin test-skip fix.
  # Drop once inputs.nixpkgs catches up.
  (final: prev: {
    nushell = (import inputs.nixpkgs-nushell {
      inherit (prev.stdenv.hostPlatform) system;
    }).nushell;
  })
  inputs.nix-openclaw.overlays.default
  inputs.claude-code.overlays.default
  (import ./pysilero-vad-darwin.nix)
]

{
  lib,
  stdenv,
  callPackage,
  makeWrapper,
  python312,
  fetchFromGitHub,
  # Flake inputs passed as arguments
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}: let
  graphiti-src = fetchFromGitHub {
    owner = "getzep";
    repo = "graphiti";
    rev = "v0.18.2";
    sha256 = "sha256-ehuojkUD1bsXLxB3wKy9UBcGHCQ0a6sxxi2CuWlCYcA=";
  };

  # Load the workspace from the MCP server subdirectory
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = graphiti-src + "/mcp_server";
  };

  # Generate overlay from uv.lock
  uvLockedOverlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # Construct Python package set using modern uv2nix API
  pythonSet =
    (callPackage pyproject-nix.build.packages {
      python = python312;
    }).overrideScope (
      lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        uvLockedOverlay
      ]
    );

  # Create virtual environment
  mcp-env = pythonSet.mkVirtualEnv "graphiti-mcp-env" workspace.deps.default;
in
  stdenv.mkDerivation {
    pname = "graphiti-mcp-server";
    version = "0.18.2";

    src = graphiti-src + "/mcp_server";

    nativeBuildInputs = [makeWrapper];
    buildInputs = [mcp-env];

    dontBuild = true;

    # Use --run to set env vars at runtime to avoid hardcoding secrets in Nix store
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/lib/graphiti-mcp

      cp -r . $out/lib/graphiti-mcp/

      makeWrapper ${mcp-env}/bin/python $out/bin/graphiti-mcp-server \
        --add-flags "$out/lib/graphiti-mcp/graphiti_mcp_server.py --transport stdio" \
        --prefix PYTHONPATH : "$out/lib/graphiti-mcp" \
        --run 'export OPENAI_API_KEY=''${OPENAI_API_KEY:-$(get-key-openai)}' \
        --run 'export MODEL_NAME=''${MODEL_NAME:-gpt-4o-mini}' \
        --run 'export NEO4J_URI=''${NEO4J_URI:-bolt://server:7687}' \
        --run 'export NEO4J_USER=''${NEO4J_USER:-neo4j}' \
        --run 'export NEO4J_PASSWORD=''${NEO4J_PASSWORD:-$(get-key-neo4j)}' \
        --run 'export NEO4J_DATABASE=''${NEO4J_DATABASE:?NEO4J_DATABASE must be set}'

      runHook postInstall
    '';

    meta = with lib; {
      description = "Graphiti MCP Server - Knowledge Graph for AI Assistants";
      homepage = "https://github.com/getzep/graphiti";
      license = licenses.asl20;
      platforms = platforms.all;
    };
  }

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
  mcp-reddit-src = fetchFromGitHub {
    owner = "jeanlucthumm";
    repo = "mcp-reddit";
    rev = "master"; # You may want to pin to a specific commit hash
    sha256 = "sha256-FfDAnEvmjvFtWMVET1NqCTQOEIpCCdZHCFt0nGAuK68=";
  };

  # Load the workspace from the project root
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = mcp-reddit-src;
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
  mcp-env = pythonSet.mkVirtualEnv "mcp-reddit-env" workspace.deps.default;
in
  stdenv.mkDerivation {
    pname = "mcp-reddit";
    version = "0.1.0";

    src = mcp-reddit-src;

    nativeBuildInputs = [makeWrapper];
    buildInputs = [mcp-env];

    dontBuild = true;

    # Use --run to set env vars at runtime to avoid hardcoding secrets in Nix store
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/lib/mcp-reddit

      cp -r . $out/lib/mcp-reddit/

      makeWrapper ${mcp-env}/bin/python $out/bin/mcp-reddit \
        --add-flags "-m mcp_reddit.reddit_fetcher" \
        --prefix PYTHONPATH : "$out/lib/mcp-reddit/src" \
        --run 'export REDDIT_CLIENT_ID=''${REDDIT_CLIENT_ID:?REDDIT_CLIENT_ID must be set}' \
        --run 'export REDDIT_CLIENT_SECRET=''${REDDIT_CLIENT_SECRET:?REDDIT_CLIENT_SECRET must be set}' \
        --run 'export REDDIT_REFRESH_TOKEN=''${REDDIT_REFRESH_TOKEN:-}'

      runHook postInstall
    '';

    meta = with lib; {
      description = "MCP Reddit Server - Reddit content fetching for MCP clients";
      homepage = "https://github.com/RobertBergman/mcp-reddit.git";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
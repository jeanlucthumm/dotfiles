{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
  python3,
  makeWrapper,
}:
buildNpmPackage {
  pname = "mcp-opennutrition";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "deadletterq";
    repo = "mcp-opennutrition";
    rev = "3477c52404dae50c0c734163d3c6a6aba97fe3d1";
    sha256 = "sha256-YNmKWZt3IoaSc6mVhYq8fcrMkA3xHmcKSz1ZmsZ6JxE=";
  };

  npmDepsHash = "sha256-Ep8cVw1O3IFbN2r16HGFmOcnDBkFxgK0U0XaVAEiF9U=";

  nativeBuildInputs = [
    nodejs
    python3
    makeWrapper
  ];

  # Skip npm install during build since buildNpmPackage handles it
  dontNpmInstall = true;

  # Custom build phase to handle TypeScript compilation and data processing
  buildPhase = ''
    runHook preBuild

    # Run the full build process including data conversion
    npm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Create output directory structure
    mkdir -p $out/lib/mcp-opennutrition
    mkdir -p $out/bin

    # Copy built application
    cp -r build/ $out/lib/mcp-opennutrition/
    cp -r data_local/ $out/lib/mcp-opennutrition/
    cp -r node_modules/ $out/lib/mcp-opennutrition/
    cp package.json $out/lib/mcp-opennutrition/

    # Create wrapper script
    makeWrapper ${nodejs}/bin/node $out/bin/mcp-opennutrition \
      --add-flags "$out/lib/mcp-opennutrition/build/index.js" \
      --chdir "$out/lib/mcp-opennutrition"

    runHook postInstall
  '';

  # Ensure the build includes the dataset
  preBuild = ''
    # Verify the dataset exists
    if [ ! -f "data/opennutrition-dataset-2025.1.zip" ]; then
      echo "Error: Dataset file not found at data/opennutrition-dataset-2025.1.zip" >&2
      echo "Please ensure the dataset is included in the source" >&2
      exit 1
    fi
  '';

  meta = with lib; {
    description = "MCP implementation for OpenNutrition dataset access";
    homepage = "https://github.com/deadletterq/mcp-opennutrition";
    license = licenses.gpl3;
    maintainers = [];
    platforms = platforms.all;
  };
}

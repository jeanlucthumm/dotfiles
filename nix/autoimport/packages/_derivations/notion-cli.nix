{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "notion-cli";
  version = "0.15.6";

  src = fetchFromGitHub {
    owner = "litencatt";
    repo = "notion-cli";
    rev = "v${finalAttrs.version}";
    hash = "sha256-HWnIFxE7rj30psvn0cGTYIDGod/Wo9vFOtprGKIu4ko=";
  };

  yarnOfflineCacheOrig = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = "sha256-FO2F4sSpNjg/IRCAPZxRDAOFfu8WA3/2sV7v8tDD1KM=";
  };

  # Copy offline cache to writable location (yarn tries to modify it)
  preConfigure = ''
    export yarnOfflineCache=$(mktemp -d)
    cp -r ${finalAttrs.yarnOfflineCacheOrig}/* $yarnOfflineCache/
    chmod -R +w $yarnOfflineCache
  '';

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    nodejs
  ];

  buildInputs = [ nodejs ];

  # Generate oclif manifest after build
  postBuild = ''
    yarn --offline oclif manifest
  '';

  # Custom install phase since npmInstallHook has issues with this package
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/notion-cli
    cp -r bin dist node_modules package.json $out/lib/notion-cli/
    cp oclif.manifest.json $out/lib/notion-cli/ || true

    mkdir -p $out/bin
    cat > $out/bin/notion-cli << EOF
#!/usr/bin/env bash
exec ${nodejs}/bin/node $out/lib/notion-cli/bin/run "\$@"
EOF
    chmod +x $out/bin/notion-cli

    runHook postInstall
  '';

  meta = {
    description = "Notion CLI tool with interactive mode for database and page operations";
    homepage = "https://github.com/litencatt/notion-cli";
    license = lib.licenses.mit;
    mainProgram = "notion-cli";
    platforms = lib.platforms.all;
  };
})

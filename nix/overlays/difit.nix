{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_10,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "difit";
  version = "2.2.7";

  src = fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    rev = "v${finalAttrs.version}";
    hash = "sha256-1YMGvzjHW0XKtMK0uRradFdRAFlCK+EeR768GYeTunY=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_10
    pnpm_10.configHook
    makeWrapper
  ];

  pnpmDeps = pnpm_10.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-ze7lwV5kb58UHu9TImAd0GgqVRm+mbeBr+Vm7A71K3E=";
    fetcherVersion = 1;
  };

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/difit
    mkdir -p $out/bin

    cp -r dist/ $out/lib/difit/
    cp -r node_modules/ $out/lib/difit/
    cp package.json $out/lib/difit/

    makeWrapper ${nodejs}/bin/node $out/bin/difit \
      --add-flags "$out/lib/difit/dist/cli/index.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI tool to view git diffs in a GitHub-style web UI";
    homepage = "https://github.com/yoshiko-pg/difit";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
    mainProgram = "difit";
  };
})

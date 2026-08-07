# Braintrust `bt` CLI (braintrustdata/bt) — query traces/logs with BTQL
# (`bt sql`, `bt view`, `bt sync pull`). Not in nixpkgs; upstream ships
# prebuilt per-platform tarballs on GitHub releases. Authenticate once with
# `bt auth login --oauth --profile ai-replit`. `bt self update` won't work
# against the read-only store — bump `version` + hashes here instead.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "0.15.1";

  artifacts = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-3KBanUtpTCTpHk13HZ2VT9Y3IHnI9y8nCfbmhHjw6yg=";
    };
    x86_64-darwin = {
      suffix = "x86_64-apple-darwin";
      hash = "sha256-6BFV9tiU70TGU87ZpbX8m6GizMd2XEGtoei6o0XgnS8=";
    };
    aarch64-linux = {
      suffix = "aarch64-unknown-linux-gnu";
      hash = "sha256-H/hjd+HW/KzPmm9klqjpTv9ymPRMuYkGyXUYyfortz4=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-L6ufjs5KwsZjhiBvpfnZBeB22lnZXjVCPWQcJFJXQLE=";
    };
  };

  artifact =
    artifacts.${stdenvNoCC.hostPlatform.system}
    or (throw "bt: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "bt";
    inherit version;

    src = fetchurl {
      url = "https://github.com/braintrustdata/bt/releases/download/v${version}/bt-${artifact.suffix}.tar.gz";
      inherit (artifact) hash;
    };

    sourceRoot = "bt-${artifact.suffix}";

    nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [autoPatchelfHook];

    installPhase = ''
      runHook preInstall
      install -Dm755 bt $out/bin/bt
      runHook postInstall
    '';

    meta = {
      description = "Braintrust CLI for querying traces, logs, and experiments";
      homepage = "https://github.com/braintrustdata/bt";
      license = lib.licenses.mit;
      mainProgram = "bt";
      platforms = lib.attrNames artifacts;
    };
  }

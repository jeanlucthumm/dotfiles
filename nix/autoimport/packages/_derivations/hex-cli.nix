# Hex CLI (hex.tech) — authoring/running Hex data notebooks from the terminal.
# Upstream ships prebuilt single-file binaries per platform (same artifacts the
# hex-inc/hex-cli Homebrew tap installs). Authenticate once with `hex auth login`.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.2026.07.28";

  artifacts = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-jqHd6BxACECHTj5IHjrHa+ISYsjDDblRtr1T5qd9uqU=";
    };
    x86_64-darwin = {
      suffix = "x86_64-apple-darwin";
      hash = "sha256-UQ8YKXyP6KzGSVG+wWVCWBc+mbVIIJGR3rbQkbNvPxs=";
    };
    aarch64-linux = {
      suffix = "aarch64-unknown-linux-gnu";
      hash = "sha256-g2jlbC/S5W49gfNkf4DnKCy0Dz7Q4oIvHNZ2vnc+gRM=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-8ijv61V39Ghin8znyWuYkGGPhgqugEI5VoqOwcpUHEA=";
    };
  };

  artifact =
    artifacts.${stdenvNoCC.hostPlatform.system}
    or (throw "hex-cli: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "hex-cli";
    inherit version;

    src = fetchurl {
      url = "https://github.com/hex-inc/hex-cli/releases/download/v${version}/hex-${artifact.suffix}.tar.xz";
      inherit (artifact) hash;
    };

    sourceRoot = "hex-${artifact.suffix}";

    nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [autoPatchelfHook];

    installPhase = ''
      runHook preInstall
      install -Dm755 hex $out/bin/hex
      runHook postInstall
    '';

    meta = {
      description = "Hex CLI for managing Hex projects, cells, and runs from the terminal";
      homepage = "https://hex.tech/product/cli";
      license = lib.licenses.unfree;
      mainProgram = "hex";
      platforms = lib.attrNames artifacts;
    };
  }

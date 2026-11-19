# Tinfoil's local proxy (tinfoilsh/tinfoil-proxy). It serves an
# OpenAI-compatible endpoint on loopback and forwards to a Tinfoil enclave,
# after checking the enclave's attestation against the public transparency log
# and encrypting request and response bodies to it. Not in nixpkgs, and the
# `tinfoil proxy` subcommand of nixpkgs' `tinfoil-cli` is gone.
{
  lib,
  # Upstream's go.mod wants Go 1.27. Use `buildGoModule` once that is the
  # default Go.
  buildGo127Module,
  fetchFromGitHub,
}:
buildGo127Module (finalAttrs: {
  pname = "tinfoil-proxy";
  version = "0.2.9";

  src = fetchFromGitHub {
    owner = "tinfoilsh";
    repo = "tinfoil-proxy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-O7JIj7aKmOoJNPpK47iEOS3T3txt2y9AbfjvPZ0uPpo=";
  };

  vendorHash = "sha256-vqE0AOXdbaqgl3LWk6OWWpNHgBSqazYqskIWs2/fCwg=";

  ldflags = ["-s" "-w" "-X main.buildVersion=v${finalAttrs.version}"];

  meta = {
    description = "Local proxy that verifies and encrypts connections to Tinfoil enclaves";
    homepage = "https://github.com/tinfoilsh/tinfoil-proxy";
    license = lib.licenses.asl20;
    mainProgram = "tinfoil-proxy";
  };
})

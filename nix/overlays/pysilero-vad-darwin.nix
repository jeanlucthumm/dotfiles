# TODO: Remove once pysilero-vad > 3.3.0 lands in nixpkgs (nixpkgs#491459)
# Upstream fix: rhasspy/pysilero-vad#15 (merged, but no release cut yet)
final: prev: prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  python3 = prev.python3.override {
    packageOverrides = pyFinal: pyPrev: {
      pysilero-vad = pyPrev.pysilero-vad.overridePythonAttrs {
        version = "3.3.0-unstable-2026-02-12";
        src = prev.fetchFromGitHub {
          owner = "rhasspy";
          repo = "pysilero-vad";
          rev = "d5fb763a592f5ffb633a494fd073ee93fe8b5445";
          hash = "sha256-gQDZuu8hN0s+yfkp22w39/Aje5/6qdX0W95FPu6obw0=";
          fetchSubmodules = true;
        };
      };
    };
  };
  python3Packages = final.python3.pkgs;
}

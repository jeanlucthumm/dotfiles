# `signStable drv`: re-sign a package's .app bundles and Mach-O executables with
# a long-lived self-signed cert so their code-signing designated requirement
# stops changing between rebuilds.
#
# Nix ad-hoc signs everything, which makes the requirement a hash of the
# binary. macOS TCC (Accessibility, Screen Recording, ...) pins grants to that
# requirement, so every upgrade silently revokes them. With a real cert the
# requirement becomes `identifier "..." and certificate root = H"<cert>"`,
# which survives any rebuild. The key is deliberately public: it ends up in
# the world-readable store anyway, and all it can do is inherit TCC grants on
# a machine an attacker already runs code on. Rotating it re-prompts everything.
#
# Identity on Linux so generic modules need no platform branch.
{pkgs}: let
  inherit (pkgs) lib;
  crt = ./nix-local.crt;
  key = ./nix-local.key;
in
  drv:
    if !pkgs.stdenv.hostPlatform.isDarwin
    then drv
    else
      pkgs.runCommand "${drv.name}-signed" {
        nativeBuildInputs = [pkgs.rcodesign pkgs.file];
        meta = drv.meta or {};
        passthru = (drv.passthru or {}) // {unsigned = drv;};
      } ''
        cp -R ${drv} $out
        chmod -R u+w $out

        # Absolute symlinks into the unsigned output must point at our copy,
        # otherwise signing would write through them into the read-only store.
        find $out -type l | while read -r l; do
          t=$(readlink "$l")
          case "$t" in
            ${drv}*) ln -sfn "$out''${t#${drv}}" "$l" ;;
          esac
        done

        sign() {
          rcodesign sign \
            --pem-file ${crt} --pem-file ${key} \
            --timestamp-url none --signing-time 2020-01-01T00:00:00Z \
            "$@"
        }

        # Bare binaries first: a bundle whose MacOS dir aliases bin/ (Neovide)
        # gets re-signed below with the bundle's CFBundleIdentifier, which wins.
        for f in $out/bin/*; do
          if [ -f "$f" ] && [ ! -L "$f" ] && file -b "$f" | grep -q '^Mach-O'; then
            sign --binary-identifier "$(basename "$f")" "$f"
          fi
        done
        for app in $out/Applications/*.app; do
          [ -d "$app" ] || continue
          # A symlinked MacOS dir (Neovide: -> ../../../bin) gets sealed as a
          # link and the executable inside is never signed. Make it real.
          m="$app/Contents/MacOS"
          if [ -L "$m" ]; then
            t=$(readlink -f "$m")
            rm "$m"
            cp -R "$t" "$m"
          fi
          sign "$app"
        done
      ''

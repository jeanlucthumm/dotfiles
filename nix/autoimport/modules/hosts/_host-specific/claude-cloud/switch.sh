#!/usr/bin/env bash
# Build and activate the root@claude-cloud Home Manager profile.
#
#   switch.sh [flake-dir]      default: ~/nix
#
# The VM's GitHub proxy returns 403 for tarball downloads of repositories not
# attached to the session, which is how `github:` flake inputs are fetched,
# while git fetches of public repositories work. So the build runs on a
# throwaway copy of the flake whose lock file names every github input by its
# git+https URL at the locked rev instead. The lock's narHash is still
# verified against what git delivers, so the store paths are exactly the ones
# flake.lock pins everywhere else, and ~/nix itself stays untouched. Re-run
# this after editing ~/nix inside a session; `nh` and plain `home-manager
# switch` fetch the lock as written and fail.
set -euo pipefail

flake="${1:-$HOME/nix}"
export PATH=/nix/var/nix/profiles/default/bin:$PATH
export USER="${USER:-root}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -r "$flake" "$work/nix"

python3 - "$work/nix/flake.lock" <<'PY'
import json
import sys

path = sys.argv[1]
lock = json.load(open(path))
for node in lock["nodes"].values():
    locked = node.get("locked")
    if not locked or locked.get("type") != "github":
        continue
    host = locked.get("host", "github.com")
    node["locked"] = {
        "type": "git",
        "url": f"https://{host}/{locked['owner']}/{locked['repo']}",
        "rev": locked["rev"],
        "narHash": locked["narHash"],
        "lastModified": locked["lastModified"],
        "shallow": True,
    }
json.dump(lock, open(path, "w"), indent=2)
PY

out=$(nix build --no-link --print-out-paths \
  "path:$work/nix#homeConfigurations.\"root@claude-cloud\".activationPackage")
"$out/activate"

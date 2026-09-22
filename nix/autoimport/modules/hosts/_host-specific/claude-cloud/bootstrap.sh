#!/usr/bin/env bash
# Setup script for Claude Code cloud environments (claude.ai/code).
#
# Paste this into the environment's "Setup script" field so the VM fetches the
# current version of this file on every rebuild of the environment snapshot:
#
#   curl -fsSL https://raw.githubusercontent.com/jeanlucthumm/dotfiles/master/nix/autoimport/modules/hosts/_host-specific/claude-cloud/bootstrap.sh | bash
#
# The environment needs "Full" network access, or a custom allowlist with
# install.determinate.systems, cache.nixos.org and raw.githubusercontent.com:
# the default "Trusted" list has no nix cache on it. The script runs as root,
# must exit zero, and must finish within about five minutes; see
# hosts/claude-cloud.nix for the measured budget. It is idempotent, so it can
# also be re-run by hand inside a session.
#
# Set DOTFILES_BRANCH to check out a branch other than master, for testing
# changes to this bootstrap before they land.
set -euo pipefail

repo=https://github.com/jeanlucthumm/dotfiles
branch="${DOTFILES_BRANCH:-master}"
export HOME=/root
export USER=root

# 1. Nix. The VM has no init system, so the installer only lays out /nix and
#    /etc/nix; root talks to the store directly, no daemon needed. The proxy
#    CA is already in the system trust store.
if [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
  curl -fsSL --proto '=https' --tlsv1.2 https://install.determinate.systems/nix \
    | sh -s -- install linux --init none --no-confirm \
      --extra-conf "ssl-cert-file = /etc/ssl/certs/ca-certificates.crt"
fi
export PATH=/nix/var/nix/profiles/default/bin:$PATH

# 2. This repository as $HOME, the same way every other machine gets it.
#    apt's yadm only does the clone; Home Manager installs its own afterwards.
if ! command -v yadm >/dev/null; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq yadm
fi
if [ ! -d "$HOME/.local/share/yadm/repo.git" ]; then
  yadm clone --no-bootstrap -b "$branch" "$repo"
fi

# 3. Build and activate the profile.
exec "$HOME/nix/autoimport/modules/hosts/_host-specific/claude-cloud/switch.sh"

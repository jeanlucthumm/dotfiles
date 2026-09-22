# Home Manager profile for Claude Code cloud sessions (claude.ai/code).
#
# The session VM is Ubuntu 24.04 x86_64, runs everything as root with
# HOME=/root, has no systemd, and clones the working repository fresh each
# session. The cloud environment's setup script (paste the one-liner from
# _host-specific/claude-cloud/bootstrap.sh) installs nix, checks this repo out
# as $HOME with yadm, and activates this profile. Anthropic snapshots the
# filesystem after the setup script and boots later sessions from that
# snapshot, so the bootstrap runs once per snapshot (rebuilt when the
# environment settings change or after about seven days), not once per
# session. Measured in the VM: nix install 7 s, input fetch plus evaluation
# 40 s, closure download 25 s.
#
# Two properties of the VM shape this host:
#   - GitHub goes through a proxy scoped to the repositories attached to the
#     session. Tarball and release-asset downloads for any other repository
#     return 403, so `github:` flake inputs cannot be fetched, while plain git
#     fetches of public repositories work. switch.sh overrides every github
#     input with its git+https twin at the locked rev: same narHash, so the
#     same store paths as everywhere else. Packages that download GitHub
#     release assets (bt, hex-cli) are left out by importing `vcs` rather
#     than all of `dev`.
#   - Claude Code's Bash tool restores a fixed PATH captured at session start,
#     so profile.d scripts never reach it. The activation step below links
#     profile binaries into /usr/local/bin, which is on that PATH.
fp @ {withSystem, ...}: {
  flake.homeConfigurations."root@claude-cloud" = withSystem "x86_64-linux" ({
    pkgs,
    system,
    ...
  }:
    fp.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit system; # required to make jlib.mkHomeManager work
      };
      modules = with fp.config.flake.modules.homeManager; [
        base
        vcs
        ({
          config,
          lib,
          ...
        }: {
          home.username = "root";
          home.homeDirectory = "/root";
          home.stateVersion = "24.05";

          # No signing keys in the VM; the harness signs commits itself.
          programs.git.signing.signByDefault = lib.mkForce false;

          # nh runs `nix build` on ~/nix without the input overrides
          # switch.sh needs, so it cannot work here. It is also not in the
          # binary cache at the pinned nixpkgs and would build from source.
          programs.nh.enable = lib.mkForce false;

          # Expose the profile (and nix itself) on a PATH entry the Bash tool
          # keeps. Runs after installPackages so the new generation's binaries
          # exist. Links from an earlier generation that no longer resolve are
          # dropped first; files that are not ours are never touched.
          home.activation.cloudPathShim = lib.hm.dag.entryAfter ["installPackages"] ''
            shim=/usr/local/bin
            for bindir in ${config.home.profileDirectory}/bin /nix/var/nix/profiles/default/bin; do
              for link in "$shim"/*; do
                if [ -L "$link" ] && [[ "$(readlink "$link")" == "$bindir"/* ]] && [ ! -e "$link" ]; then
                  run rm "$link"
                fi
              done
              for bin in "$bindir"/*; do
                target="$shim/$(basename "$bin")"
                if [ ! -e "$target" ] || { [ -L "$target" ] && [[ "$(readlink "$target")" == "$bindir"/* ]]; }; then
                  run ln -sfn "$bin" "$target"
                fi
              done
            done
          '';
        })
      ];
    });
}

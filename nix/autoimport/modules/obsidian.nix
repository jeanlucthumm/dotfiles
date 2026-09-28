# Server-side care of the Obsidian vault. The vault is Syncthing-shared and
# edited by phone, laptops and the claude rc agents; the server's folder is
# sendreceive, so whatever happens here syncs out.
#
# Durability: a local git repo turns the vault into a timeline. Every minute
# a pass commits whatever is dirty ("changes from server on <date>"). Clean
# tree = no commit. `.git` is in the Syncthing ignore list, so the repo is
# server-local and never syncs out; backups.nix copies it to the ZFS pool
# nightly. git-sync (agent-memory.nix) isn't reused because it insists on a
# remote to push to.
#
# Media: attachments do not belong in a tree that is committed every minute,
# mirrored through iCloud and held by every device. Blobs live once under
# /srv/blobs (its own tank dataset), nginx serves them read-only under
# /media/, and notes hold URLs. Design and rollout:
# nix/proposals/vault-media-offload/PROPOSAL.md.
{
  flake.modules.nixos.homeServer = {
    config,
    pkgs,
    ...
  }: let
    vault = "/home/jeanluc/obsidian/vault";
    blobs = "/srv/blobs";
  in {
    systemd.services.vault-autocommit = {
      description = "Commit Obsidian vault changes if dirty";
      path = [pkgs.git];
      serviceConfig = {
        Type = "oneshot";
        User = "jeanluc";
        Group = "users";
        WorkingDirectory = vault;
      };
      script = ''
        if [ ! -e .git ]; then
          git init -q -b main
          git config user.name vault-autocommit
          git config user.email vault-autocommit@server.local
        fi
        git add -A
        if ! git diff --cached --quiet; then
          git commit -q -m "changes from $(uname -n) on $(date -Is)"
        fi
      '';
    };

    systemd.timers.vault-autocommit = {
      description = "Commit Obsidian vault changes every minute";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
      };
    };

    # Blob store. The pool is encrypted and unlocked by hand after boot; until
    # then this is an empty directory on the root filesystem, which the
    # dataset later mounts over (overlay=on). Anything that writes here must
    # gate on ConditionPathIsMountPoint or its output vanishes at unlock.
    systemd.tmpfiles.rules = ["d ${blobs} 0755 jeanluc users -"];

    # Names are content-addressed (`stem-<sha256[:8]>.ext`), so a URL never
    # changes meaning: cache forever. Reachable from the phone only through
    # tailscale serve (proxy.nix), because Obsidian mobile refuses plain http.
    services.nginx.virtualHosts.${config.networking.hostName}.locations."/media/" = {
      alias = "${blobs}/";
      extraConfig = ''
        autoindex off;
        add_header Cache-Control "public, max-age=31536000, immutable";
      '';
    };

    # Notes point at these forever; losing one is a dangling link, so
    # backup-grade retention. Its own dataset so rolling back tank/backups
    # never rolls back blobs. Template defined in storage/backups.nix.
    services.sanoid.datasets."tank/blobs".useTemplate = ["critical"];
  };
}

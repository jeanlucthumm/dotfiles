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
    lib,
    pkgs,
    ...
  }: let
    vault = "/home/jeanluc/obsidian/vault";
    blobs = "/srv/blobs";
    # The sweeper logs its plan and changes nothing while this is true. Flip
    # after the migration dry run reads clean (proposal, "Manual steps").
    sweepDryRun = true;
    # What the sweeper moves, and therefore what the autocommit must never
    # record: a minute-cadence `git add -A` would capture every dropped PDF
    # long before the sweeper's quiet period ends. One list, two consumers.
    # Images become embeds in notes, everything else a plain link.
    mediaExts = {
      image = ["png" "jpg" "jpeg" "gif" "webp" "svg" "bmp"];
      other = ["m4a" "mp3" "wav" "ogg" "flac" "webm" "mp4" "mov" "mkv" "pdf"];
    };
    # `pdf` -> `*.[pP][dD][fF]`: gitignore matching is case-sensitive here.
    ignorePattern = ext:
      "*."
      + lib.concatMapStrings (c: "[${lib.toLower c}${lib.toUpper c}]")
      (lib.stringToCharacters ext);
    mediaExcludes =
      lib.concatMapStrings (e: ignorePattern e + "\n")
      (mediaExts.image ++ mediaExts.other);
    # Wrapped so the paths have one home (here) and the tool is on PATH for
    # hand runs: `obsidian-media-sweep --dry-run --limit 3`.
    sweepPy = pkgs.writers.writePython3Bin "obsidian-media-sweep-py" {}
      (builtins.readFile ./_obsidian-media-sweep.py);
    sweep = pkgs.writeShellApplication {
      name = "obsidian-media-sweep";
      runtimeInputs = [config.services.tailscale.package];
      text = ''
        exec ${sweepPy}/bin/obsidian-media-sweep-py \
          --vault ${lib.escapeShellArg vault} --store ${lib.escapeShellArg blobs} \
          --image-exts ${lib.concatStringsSep "," mediaExts.image} \
          --other-exts ${lib.concatStringsSep "," mediaExts.other} "$@"
      '';
    };
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
        # Media never enters history; the sweeper owns it. Repo-local exclude
        # rather than a .gitignore in the vault, so it cannot be edited away
        # from another device. Other tools (Claude Code) write their own lines
        # to this file, so only our marked block is replaced. Files already
        # tracked stay tracked until the sweeper deletes them.
        ex=.git/info/exclude
        {
          if [ -f "$ex" ]; then
            sed '/^# BEGIN obsidian.nix media/,/^# END obsidian.nix media/d' "$ex"
          fi
          printf '# BEGIN obsidian.nix media\n%s# END obsidian.nix media\n' \
            ${lib.escapeShellArg mediaExcludes}
        } > "$ex.tmp"
        mv "$ex.tmp" "$ex"
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

    # Media sweeper: attachments that landed in the vault are copied to the
    # store, their wikilinks rewritten to URLs, and the vault copy deleted.
    # An unreferenced one leaves a same-named `<file>.md` stub holding the
    # link where it was, so nothing points into the void and no note is ever
    # appended to twice.
    # A quiet period on the attachment and on every referencing note keeps it
    # from editing a note someone is typing in on the phone. The URL prefix is
    # this node's MagicDNS name, read from tailscaled at run time.
    environment.systemPackages = [sweep];

    systemd.services.obsidian-media-sweep = {
      description = "Move vault media to the blob store, leave URLs in notes";
      # Skipped, not failed, until the pool is unlocked and mounted here.
      unitConfig.ConditionPathIsMountPoint = blobs;
      serviceConfig = {
        Type = "oneshot";
        User = "jeanluc";
        Group = "users";
        ExecStart = lib.escapeShellArgs (
          ["${sweep}/bin/obsidian-media-sweep"]
          ++ lib.optional sweepDryRun "--dry-run"
        );
      };
    };

    systemd.timers.obsidian-media-sweep = {
      description = "Sweep vault media every 5 minutes";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}

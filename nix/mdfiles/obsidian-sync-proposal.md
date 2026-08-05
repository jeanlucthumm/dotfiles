# Obsidian Vault Sync & History Proposal

## Goal

Give the Obsidian vault a continuous, machine-independent **commit trail** — the ability to
see how a note evolved, diff it, and recover it — and close the gap where iOS edits only
reach the server when the MacBook happens to be awake.

## Current State

Verified 2026-07-26.

**Vault location.** The live vault is in iCloud on the MacBook:

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/vault
```

142M total; 68M of that is non-markdown (write-once `.m4a` voice recordings and PNGs).

**Syncthing already bridges iCloud → server.** MacBook folder `xyrfm-qkrya` points *directly*
at the iCloud path above. The server receives it at `/home/jeanluc/obsidian/vault` as
`receiveonly`; desktop also participates. This works today — files edited on the MacBook
appear on the server within seconds.

**obsidian-git is the broken part.** From `.obsidian/plugins/obsidian-git/data.json`:

| Setting | Value | Consequence |
|---|---|---|
| `autoSaveInterval` | `1440` | Commits once per 24h *of Obsidian uptime*, not wall-clock |
| `disablePush` | `true` | Nothing is pushed |
| remotes | *none configured* | Nothing can be pushed |

Result: 24 commits total since 2026-02-28, all local to the MacBook. Gaps of 3–14 days.

**Backups do exist** (this corrects an earlier assumption that they didn't):

- `home-backup` rsyncs `/home/jeanluc/` → `/srv/backups/home/` weekly (Sun 14:00); the vault
  is in scope — 567 entries present on disk
- `tank/backups` carries sanoid `critical` retention (14 daily + 4 weekly), snapshotting
  daily at 14:15; 75 snapshots live pool-wide

So disaster recovery is covered at **weekly granularity with ~1 month of retention**, on
redundant scrubbed ZFS. What's missing is granularity and a trail.

**A latent problem:** the MacBook's `.stignore` contains only `.obsidian/workspace.json`, so
its 68M `.git` directory is being replicated to desktop over Syncthing. Git objects through a
file syncer is a known corruption vector.

## Problem

1. **No evolution history.** ZFS snapshots are weekly full-tree mirrors — no diffs, no blame,
   no "when did this line change."
2. **Weekly blind spot.** Anything created and deleted between Sunday rsyncs is invisible.
3. **Snapshots are laptop-gated twice over** — they require the MacBook to be on *and*
   Obsidian to have been open for 24 continuous hours.
4. **iOS edits are laptop-gated.** Phone → iCloud is instant, but iCloud → server requires the
   MacBook awake. Days offline means days of edits absent from the server.
5. **`.git` replicating over Syncthing** between MacBook and desktop.

## Architecture

```
┌──────────┐   iCloud    ┌─────────────────┐   Syncthing   ┌────────────────────────┐
│   iOS    │────────────▶│   Mac Studio    │──────────────▶│  Server (NixOS, 24/7)  │
│ (Obsidian│             │  (always-on)    │               │                        │
│  mobile) │             │  SOLE BRIDGE    │               │  /home/jeanluc/        │
└──────────┘             └─────────────────┘               │    obsidian/vault      │
                                  ▲                        │    (receiveonly)       │
                            iCloud│                        │          │             │
                                  ▼                        │  hourly  │ systemd     │
                         ┌─────────────────┐               │  timer   ▼             │
                         │    MacBook      │               │  ┌──────────────────┐  │
                         │  iCloud ONLY    │               │  │ git add -A       │  │
                         │  (no Syncthing  │               │  │ commit if dirty  │  │
                         │   on this vault)│               │  └────────┬─────────┘  │
                         └─────────────────┘               └───────────┼────────────┘
                                                                       │
                         ┌─────────────────┐   Syncthing               ▼
                         │ Desktop (NixOS) │◀─────────────  /srv/backups/
                         │  Syncthing only │                  obsidian-vault.git
                         └─────────────────┘                  (on tank, sanoid'd)
```

Two independent layers, deliberately decoupled:

- **Syncthing** keeps the server replica hot — near-instant, continuous.
- **The hourly timer** coalesces whatever landed into one commit. The interval *is* the
  coalescing; there is no watching.

## Key Design Decision: Detached Work-Tree

The git directory lives **only** on tank. Nothing named `.git` ever exists inside the
Syncthing folder:

```
/home/jeanluc/obsidian/vault/     <- pristine working tree, no .git
/srv/backups/obsidian-vault.git/  <- repo + index, on ZFS with sanoid
```

```bash
git --git-dir=/srv/backups/obsidian-vault.git \
    --work-tree=/home/jeanluc/obsidian/vault \
    add -A
```

This is the same pattern yadm uses for dotfiles. It buys:

- **No ignore rules to maintain** — there's no `.git` for Syncthing to accidentally replicate
- **No push step** — commits land directly in the ZFS-snapshotted repo; no remote, no auth,
  no second copy of the objects
- **Objects inherit sanoid retention for free**, since `tank/backups` is already covered by
  the `critical` template

## Why Not git-sync

git-sync is the natural candidate (it's already the pattern in `autoimport/modules/agent-memory.nix`),
but its Linux service is **not interval-driven**. `ExecStart` is `git-sync-on-inotify`:

```bash
while true; do
  changedFile=$(inotifywait "$GIT_SYNC_DIRECTORY" -r -e modify,move,create,delete \
                  --format "%w%f" --exclude '\.git' -t "$GIT_SYNC_INTERVAL")
  if [ -z "$changedFile" ]; then
    $GIT_SYNC_COMMAND -n -s          # timeout path
  else
    git check-ignore "$changedFile" || $GIT_SYNC_COMMAND -n -s   # fires immediately
  fi
done
```

`interval` is a **max-wait ceiling, not a rate limit** — any change syncs immediately. Pointed
at a directory Syncthing is actively writing into, that yields a commit per delivery burst,
which is the opposite of an hourly coalesced snapshot.

There's also no Linux escape hatch. The Darwin fix in `agent-memory.nix:75`
(`launchd.agents.git-sync-agent-memory.config.WatchPaths = lib.mkForce []`) works because on
macOS the watching belongs to launchd, so home-manager exposes it. On Linux the watching is
*inside the ExecStart binary*, so there is nothing to override short of replacing `ExecStart`.

**Related finding:** that same `WatchPaths` default is the likely cause of the agent-memory
commit explosion. The Darwin branch sets both `StartInterval` *and* `WatchPaths = [ repo.path ]`;
launchd fires the job on directory changes independently of the interval, and git-sync commits
whenever the tree is dirty — so each triggering write became its own commit instead of one per
43200s. Note launchd `WatchPaths` is kqueue-based and **not recursive**: it fires on entries
created/deleted/renamed directly in the watched directory, not on content edits to existing
files and not on subdirectories. If the observed explosion was broader than that, something
else is also in play.

Given the server replica is `receiveonly` and the timer is its only writer, we never pull,
rebase, or merge — which is git-sync's entire value proposition. A oneshot timer is the
smaller artifact here.

## Implementation Steps

### 1. Seed the repo from existing history

Preserves the 24 commits back to 2026-02-28. **Must happen before step 4**, since deleting
`.git` on the MacBook propagates that deletion to desktop over Syncthing.

On the server:

```bash
git init --bare /srv/backups/obsidian-vault.git
```

On the MacBook:

```bash
cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/vault
git remote add tank ssh://server/srv/backups/obsidian-vault.git
git push tank master
```

Back on the server — flip to non-bare and seed the index from HEAD:

```bash
git --git-dir=/srv/backups/obsidian-vault.git config core.bare false
git --git-dir=/srv/backups/obsidian-vault.git \
    --work-tree=/home/jeanluc/obsidian/vault reset -q
```

> The `reset` matters. A bare repo has no index; without seeding it from HEAD, the first
> `git add -A` cannot record deletions relative to `HEAD` and the initial commit would be wrong.

### 2. Server module

New file, e.g. `autoimport/modules/obsidian-snapshot.nix`, following the shape of
`storage/backups.nix`:

```nix
# Hourly git snapshots of the Syncthing-replicated Obsidian vault.
#
# The repo lives on tank (sanoid-covered) with the work-tree pointed at the
# Syncthing replica, so no .git ever exists inside the synced folder. The vault
# is receiveonly and this timer is the repo's only writer, so there is never
# anything to pull, rebase, or merge.
{
  flake.modules.nixos.homeServer = {pkgs, ...}: let
    vault = "/home/jeanluc/obsidian/vault";
    repo = "/srv/backups/obsidian-vault.git";
  in {
    systemd.tmpfiles.rules = [
      "d ${repo} 0755 jeanluc users -"
    ];

    systemd.services.obsidian-snapshot = {
      description = "Snapshot Obsidian vault into git";
      path = [pkgs.git];
      serviceConfig = {
        Type = "oneshot";
        User = "jeanluc";
        Group = "users";
      };
      script = ''
        set -eu
        export GIT_DIR=${repo}
        export GIT_WORK_TREE=${vault}

        # Inert until the repo is seeded (step 1) and the vault exists.
        [ -e "$GIT_DIR/HEAD" ] || exit 0
        [ -d "$GIT_WORK_TREE" ] || exit 0

        git add -A
        git diff --cached --quiet && exit 0
        git commit -q -m "vault: $(date -Iseconds)"
      '';
    };

    systemd.timers.obsidian-snapshot = {
      description = "Hourly Obsidian vault snapshot";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };
}
```

`Persistent = true` matches the existing backup timers, so a missed run after downtime
catches up.

### 3. Retire obsidian-git

In Obsidian: disable/uninstall the plugin. Optionally keep it *installed but with autosave
off* if the in-app history browser and diff view are still wanted — repoint it read-only at
the tank repo.

### 4. Stop `.git` replicating over Syncthing

After step 1 has captured the history, delete `.git` from the MacBook vault. If the plugin is
kept for its history viewer, instead add `.git` to the MacBook's `.stignore`.

### 5. Mac Studio as sole bridge (when hardware arrives)

The Studio replaces the MacBook as the iCloud↔Syncthing relay. It joins as an ordinary node —
`sendreceive` is the Syncthing default, so nothing special to configure. (Worth knowing *why*
bidirectional matters, in case it's ever tempting to make it `sendonly`: desktop is Linux with
no iCloud, so desktop→iOS routes through the Studio.) The server stays `receiveonly` — purely
the backup sink.

**The MacBook should drop out of the Obsidian Syncthing folder.** This is the one part of the
Studio migration that needs a deliberate action. If both Macs hold the iCloud vault *and* both
run Syncthing against it, you have two independent sync systems managing the same directory on
two machines — Syncthing's scanner racing iCloud's writer, mtime skew between machines
receiving the same iCloud update at different times, and version-vector divergence on files
whose contents are identical. That's the standard reason running Syncthing on top of
iCloud/Dropbox is discouraged, and doubling the Macs doubles the exposure.

The MacBook loses nothing by leaving: it still has the full vault via iCloud. Final topology:

| Host | iCloud | Syncthing (Obsidian folder) |
|---|---|---|
| iOS | yes | — |
| MacBook | yes | **no** |
| Mac Studio | yes | yes (default `sendreceive`) |
| Desktop | no | yes |
| Server | no | yes (`receiveonly`) |

Three Studio-specific settings:

- **Do not run Obsidian on the Studio.** It is a relay, not an editing device. Every Obsidian
  session rewrites ~10 shared config files (see "`.obsidian/` churn" below); running it on the
  Studio adds a third writer to files that already collide between MacBook and iPhone.
- **Disable "Optimize Mac Storage."** iCloud evicts file contents to placeholders under
  storage pressure, and Syncthing will propagate that truncation outward. 142M won't trigger
  it, but a Studio also holding media might.
- **Keep it logged in.** iCloud Drive does not sync at the loginwindow.

## What This Does Not Change

- `home-backup` keeps rsyncing the vault weekly. Redundant once the git trail exists, but it's
  a different failure mode and costs nothing — leave it.
- Sanoid retention on `tank/backups` is unchanged; the repo simply inherits it.
- Server folder stays `receiveonly`.

## Notes

- **No git-LFS.** The 68M of non-markdown is write-once audio and images. Git dedupes by
  content hash, so hourly commits of unchanged binaries cost nothing; real growth tracks
  genuinely new content. Auto-gc on commit should suffice.
- **The vault's existing `.gitignore` is already correct** — it covers `.st*` (Syncthing temp
  files, `.stfolder`, `.stversions`), `.trash/`, `.obsidian/workspace*.json`, `.DS_Store`, and
  `.direnv`. Reuse as-is. Consider adding `.claude/settings.local.json`.
- **`.obsidian/` churn is the real conflict surface — and it's iCloud's, not Syncthing's.**
  Every mobile session rewrites `app.json`, `appearance.json`, `core-plugins.json`,
  `community-plugins.json`, and ~5 plugin `data.json` files. Workspace state is *safe*:
  `workspace.json` (desktop) and `workspace-mobile.json` (mobile) are separate files by design.
  As of 2026-08-02 the vault holds 3 iCloud conflict artifacts in `.obsidian/`
  (`app 2.json`, `appearance 2.json`, `core-plugins 2.json`, all 2025-03-06) plus 7 in notes —
  and **zero** `.sync-conflict-*` files, i.e. Syncthing has never produced a conflict here.
  iCloud has no ignore mechanism, so this surface cannot be configured away; it is inherent to
  sharing `.obsidian/` across devices over iCloud. Mitigation is behavioural: don't leave
  Obsidian open on two devices, and don't run it on the Studio at all.
- **Conflict artifacts were cleaned up 2026-08-02.** 10 iCloud duplicates removed (7 daily-note
  ` 2.md` stubs, all 10-byte skeletons whose base files held the real content, plus the 3
  `.obsidian/` config duplicates). `Meeting with Insomnia 2.md` was a 50KB note with no base
  file, so it was renamed rather than deleted. Vault is now clean of conflict artifacts.
- **Commit timestamps reflect Syncthing delivery, not editing time.** Acceptable, but worth
  knowing when reading history.
- **A commit can catch a torn mid-transfer state.** Self-correcting — the next hourly commit
  captures the settled tree.
- The existing `mdfiles/syncthing-proposal.md` (declarative certs via agenix) is a separate,
  still-unexecuted proposal. Current Syncthing config hardcodes device IDs in
  `autoimport/modules/hosts/_host-specific/server/syncthing.nix`.

## Open Questions

- [ ] Should desktop stay in the Obsidian Syncthing folder, or also move to Studio-only?
- [ ] Commit messages: bare timestamp, or include a changed-file summary in the body?
- [ ] Add Syncthing `staggered` versioning on the server folder as a third layer, or is
      git + sanoid enough?
- [ ] Explicit `git gc` timer, or rely on auto-gc?
- [ ] Gitignore `.obsidian/plugins/*/data.json` and the core config files? Every mobile session
      rewrites them, so leaving them tracked means an hourly commit of ~10 files of pure noise
      each time you open Obsidian on the phone. Cost of ignoring: no history for plugin
      settings.
- [ ] Does the Studio also take over the other Syncthing folders (`default`, timewarrior)?
- [ ] Is hourly right, or should it be finer (15m) now that commits are cheap?

## Resources

- [git bare repo + detached work-tree (yadm's model)](https://yadm.io/docs/overview)
- [systemd.timer OnCalendar](https://www.freedesktop.org/software/systemd/man/systemd.time.html)
- [Syncthing ignore patterns](https://docs.syncthing.net/users/ignoring.html)
- [sanoid templates](https://github.com/jimsalterjrs/sanoid)
- `autoimport/modules/agent-memory.nix` — existing git-sync integration and its Darwin
  `WatchPaths` workaround
- `autoimport/modules/storage/backups.nix` — existing backup timers and sanoid config

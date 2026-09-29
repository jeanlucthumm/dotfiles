# Vault media out of band: blobs on server, URLs in notes

Status: research done, nothing built.
Date: 2026-09-26

Evidence tags: [docs] vendor/help docs, [src] read in source, [forum] user
reports, [unv] unverified, [inferred] my reasoning.

## Trigger

The vault carries ~68M of write-once binaries (PNG pastes, iOS voice memos,
some PDFs) inside a tree that is Syncthing-shared to every device, mirrored
through iCloud to the phone, and committed every minute by
`vault-autocommit` (obsidian-vault.nix). Blobs have no business in any of
those three: they bloat the git history, ride iCloud twice, and every
device holds every attachment forever.

Goal: notes hold only pointers. The bytes live once, on server, on tank.

Constraints:

- The phone is a capture and editing device. It is always on the tailnet.
- Pointers are URLs, never paths. Obsidian on iOS cannot follow a path
  outside the vault, and the iCloud path differs per host anyway.
- Obsidian mobile refuses plain `http://` for external content on both
  Android and iOS (platform cleartext restriction, Obsidian does not opt
  out) [forum]. HTTPS is mandatory.
- "Pointers only" is the bar. A PDF that becomes a plain link is fine; no
  inline viewer required.
- **Every blob is referenced by a note.** Normally the note it was dropped
  on. If nothing links to it (dropped on the file tree, embed deleted
  later), the sweeper leaves a stub note named `<file>.md` where the file
  was, holding only the link, then moves the file as usual. The pointer
  always has a home, in the folder the human put the file in. Stubs are
  write-once and never appended to, so there is no shared note to protect
  and no convention to remember. `<file>.md` rather than `<stem>.md`
  because the stem may already be a real note; Obsidian displays it as
  `<file>` anyway.
- Simplest thing that works. One sweeper on server, no plugins, no upload
  API. Capture-time shortcuts are explicitly deferred (see Rejected).

## Verdicts

- **Inline rendering of external URLs is images only** [docs]. External
  PDFs render as a broken image [docs, forum]. External audio is
  undocumented; test one `.m4a` on the phone before migrating voice memos
  [unv].
- **HTTPS via `tailscale serve`.** Tailscale completes the Let's Encrypt
  DNS challenge for `server.<tailnet>.ts.net`, so the phone trusts the cert
  with nothing installed and nothing is exposed publicly. The hostname
  lands in CT logs; accepted, the name is generic.
  Declared in Nix as a oneshot after `tailscaled`: `tailscale serve reset`
  then `tailscale serve --bg --https=443 http://127.0.0.1:80`. `--bg` also
  persists the config in tailscaled's state across reboots, so the unit is
  belt and braces. The nixpkgs `services.tailscale.serve` option is not
  usable here: it configures Tailscale Services (`svc:` virtual IPs), whose
  hosts must be tag-identity nodes, and server is user-authenticated.
  Measured on server 2026-09-27: tailscale 1.102.4, HTTPS certs enabled for
  the tailnet (`CertDomains` non-empty), no serve config yet.
  Reset caveats: `serve reset` clears every serve and funnel entry on the
  node, so this unit must be the sole owner of serve config. It only
  re-runs when its text changes; the port closes for milliseconds then. The
  cert is cached in tailscaled's state keyed by domain, not by serve entry,
  so a reset does not re-issue [unv; check `/var/lib/tailscale/certs`
  mtimes after the first rebuild]. Let's Encrypt rate limits bite only on
  repeated issuance. The CLI needs tailscaled's socket, so order after
  `tailscaled.service` and retry on failure.
- **The hostname is load-bearing.** Every pointer embeds
  `server.<tailnet>.ts.net`. Renaming or replacing the machine breaks every
  URL unless the successor takes the same MagicDNS name. Tailscale Services
  would decouple that (see Rejected); until then, treat the name `server`
  as permanent.
- **Gitignore is mandatory, not tidy.** `vault-autocommit` runs
  `git add -A` every minute, so any blob that touches the vault is
  committed before any sweep can move it. Media globs go into the vault's
  `.gitignore` first. The 68M already in history stays; not worth a rewrite.
- **The sweeper runs on server.** The vault folder is already sendreceive
  (syncthing.nix, because the rc agents write into it), so server edits
  propagate. Headless is irrelevant: it is a oneshot + timer shaped like
  `vault-autocommit`.
- **Link rewriting is a stop-gap, behind a seam.** The proper version is
  the `mv` op in vault-cli-headless, which is its own workstream (possibly
  open source). The sweeper ships with a minimal rewrite and swaps to the
  CLI when it exists. The seam is two calls: `refs(attachment) -> [notes]`
  and `rewrite(attachment, url) -> [changed notes]`. The stop-gap handles
  wikilinks only, `![[name]]`, `![[name|alias]]`, `[[name]]`,
  `[[name|alias]]`, matched on basename, case-insensitive. Anything else
  (`#anchor`, `^block`, markdown-style links, references inside YAML
  frontmatter, links inside code fences) is detected but not rewritten, and
  as a backstop any plain-text mention of the filename that the parser did
  not account for counts as unrewritable too. Such a file, or one whose
  basename is not unique in the vault, is left alone and logged. Correct but
  incomplete beats clever; the CLI closes the gap later.
- **The chore agent does not do this.** A blob move is deterministic and
  belongs in a script, not a session.

## Design

**Flow.** Drop a file onto a note in Obsidian, on any device, as today.
Obsidian copies it into the attachment folder and inserts `![[x.pdf]]`. The
blob syncs to server. After a quiet period the sweeper stores it, rewrites
the embed to a URL, and deletes the vault copy. Syncthing carries the edit
and the delete back out; the Mac mini relays both into iCloud for the
phone. The user sees the local embed for a few minutes, then a link.

**Race.** The sweeper edits a note the user may still be typing in on the
phone, which is exactly the iCloud conflict surface the sync proposal
documents. Mitigation: only touch an attachment whose mtime, and whose
every referencing note's mtime, are older than the quiet period.

**Store.** Literally a directory: `/srv/blobs/`, flat, one file per blob.
No database, no index; the filename is the key and the notes are the only
index that matters.

- *Writes.* The sweeper and the vault replica are on the same machine, so
  a write is `cp` from the vault into `/srv/blobs/`, hash the copy, then
  `rm` the vault copy. Not rsync (nothing crosses the network) and not
  `mv` (the vault sits on the root filesystem and the store on tank, so a
  move is a copy anyway, and verify-before-delete is the whole point).
- *Reads.* nginx `location /media/` with `alias /srv/blobs/`, read-only,
  `autoindex off`. Files 0644 and the directory 0755 so the nginx user can
  read what `jeanluc` wrote; a tmpfiles rule creates the directory like
  backups.nix does for `/srv/backups/*`.
- *ZFS.* A dataset, not a partition: `zfs create -o mountpoint=/srv/blobs
  tank/blobs`, run once on server. Datasets share the pool's space (12.3T
  free on 2026-09-26), so there is nothing to size. Measured on server
  2026-09-26: the pool and its datasets are not declared in Nix (no
  `extraPools`, no `fileSystems`; backups.nix only names them for sanoid),
  the four existing datasets use ZFS-native mountpoints under `/srv/`, and
  children inherit the pool's encryption (`keylocation=none`), so the new
  one is encrypted with no extra step. Its own dataset rather than a
  subdirectory of `tank/backups` because sanoid retention and rollback are
  per dataset: `/srv/backups` holds copies, this is a primary, and rolling
  back a backup snapshot must not roll back blobs. Template `critical`, not
  `storage`: notes point at these forever and losing one is a dangling
  link.
- *Encrypted pool, unlocked by hand.* `tank` is aes-256-gcm with
  `keylocation=prompt` and there is no import unit, so after a reboot
  nothing on tank exists until someone runs the unlock (vault note "Home
  Server Storage": `zpool import`, `zfs mount -a`). `overlay=on`, so a
  dataset mounts over a non-empty directory without complaint. Hazard: the
  tmpfiles rule creates `/srv/blobs` on the root filesystem at boot; a
  sweep before unlock would write blobs there, and the dataset would then
  mount over them, hiding them from nginx and from sanoid. Guard:
  `ConditionPathIsMountPoint=/srv/blobs` on the sweeper unit, so it is a
  no-op until the pool is up. nginx just 404s until unlock, same failure
  class as every other tank consumer. (`vault-backup` has the same
  exposure today; out of scope here.)
- *URL prefix.* Not hardcoded: the sweeper reads this node's MagicDNS name
  from `tailscale status --json` at run time. The repo is public and the
  tailnet name has no business in it.
- *Nix changes.* One sanoid dataset entry, one tmpfiles rule, one nginx
  location, the sweeper unit with the mountpoint condition, the
  tailscale-serve oneshot.
- *Growth.* Flat is fine into the tens of thousands of files. Shard by hash
  prefix only if it ever matters.

**Naming.** Stored as `<stem>-<sha256[:8]>.<ext>`, e.g.
`invoice-a3f9c2d1.pdf`. The hash exists because the vault-relative name
stops being unique the moment the sweeper deletes the original: the next
`invoice.pdf` would land on the same URL and silently replace the old one.
A content hash makes collisions impossible without any lookup, makes a
re-dropped identical file resolve to the same URL, and doubles as the copy
verification. Suffix rather than prefix so names sort and read by stem;
the extension stays last so nginx and Obsidian type the file correctly.
Alternative considered: a date suffix with `-1` on collision. Needs
collision-handling code, no dedupe.

## Sweeper sketch

Oneshot + timer in `autoimport/modules/obsidian.nix` (see Dendritic
placement), User `jeanluc`, every few minutes.

1. Find files by media extension in the vault, excluding `.obsidian/` and
   `.trash/`, with mtime older than the quiet period.
2. Resolve referencing notes with `refs`. Any referencing note inside the
   quiet period: skip this tick. Any reference the stop-gap cannot rewrite,
   or a non-unique basename: skip and log. Zero references: a stub note
   will be the reference (step 4).
3. Copy to the store under the hashed name. Verify before anything else.
4. Referenced: `rewrite`. An embedded image `![[x.png|300]]` becomes
   `![300](URL)`; a bare `[[x.png]]` stays a link; everything else becomes
   `[alias or name](URL)`. Quiet checks use mtimes snapshotted before the
   run writes anything, so the sweeper's own rewrites never defer sibling
   attachments.
   Unreferenced: write `<file>.md` next to where the file was, containing
   `![name](URL)` for images so they preview, `[name](URL)` otherwise. If
   that name already exists and is not our stub, leave the attachment alone
   and log it, before anything is copied. No rewrite needed.
5. Delete the vault copy.

Never delete before the copy is verified. On any failure leave the file
alone; the next tick retries. Stubs are the only place the sweeper creates a
reference rather than rewriting one; a search for `.png.md`, `.pdf.md` and
friends lists them.

## Migration

1. Gitignore first.
2. Dry-run the sweeper over the existing media. First dry run against the
   live vault replica, 2026-09-28: 37 files (17 pdf, 15 m4a, 5 png), 0
   skipped, 15 unreferenced; spot-checked four of those and nothing in the
   vault mentions them in any form; none of the 15 stub names collides with
   an existing file. Trash the obvious junk first so nothing gets stubbed for
   no reason.
3. Verify one external `.m4a` renders on the phone. If not, exclude
   `*.m4a` and voice memos stay in the vault.
4. Run for real. `vault-backup` shrinks to text; the blob dataset is covered
   by sanoid directly.

## Rejected or deferred

- **Capture-time upload plugins.** Custom Image Auto Uploader [docs: iOS,
  S3/R2/MinIO/WebDAV] and S3 Image Sync [docs: iOS, on-demand] would keep
  pasted images out of the vault entirely and avoid the note-edit race, but
  need an upload API on server and per-device config, and cover images
  only. Deferred until the quiet-period delay is shown to be annoying.
- **Garage (S3) as the store.** Only justified by S3-speaking plugins.
  Notes kept for if that day comes: NixOS `services.garage`, nixpkgs
  `garage_2`, single node `replication_factor = 1`, S3 API on localhost via
  `tailscale serve --https=8443` (never behind a path prefix, SigV4 signs
  the path), reads via `garage bucket website --allow` behind nginx with
  Host set to the bucket name, imperative bootstrap.
- **Shell wrapper and desktop Attachment Uploader** calling a `put` over
  ssh for immediate links. Early optimization; the sweeper path already
  covers desktop.
- **iCloud folders as a second inbox** (scans, downloads bridged by the Mac
  mini). Viable later: the Mac-vs-server path mismatch is irrelevant once
  pointers are server URLs, and the pinned xattr already handles eviction
  stubs. Fits the stub mechanism as-is: files from the replica are
  unreferenced by definition and each leaves a stub in the replica folder.
  Phase 2 if the habit sticks.
- **Tailscale Services** (`svc:media`) for a prettier
  `media.<tailnet>.ts.net` URL, declarable with `services.tailscale.serve`.
  Needs server re-authenticated as a tagged node, plus service creation and
  host approval in the admin console. Revisit if the node gets tagged for
  other reasons.
- **iCloud as the store itself**, nginx serving the Syncthing replica.
  Links rot on every rename, move or delete in Finder. No.

## PR plan

One PR, several commits, deliberately against the one-commit rule so the
pieces stay reviewable in order. Commits, in stack order:

1. **proposal**: this doc plus the supersession line in the sync proposal.
2. **ts-serve**: oneshot unit, `tailscale serve reset` then
   `serve --bg --https=443 http://127.0.0.1:80`, homeServer role, next to
   proxy.nix. Live on deploy: every existing nginx location gains HTTPS
   from the phone.
3. **blob-store**: tmpfiles `d /srv/blobs 0755 jeanluc users -`; nginx
   `location /media/` alias, read-only, `autoindex off`; sanoid `tank/blobs`
   under `critical`. Inert without the sweeper. Optional rider: the same
   mountpoint condition on `vault-backup`, same file, same hazard.
4. **sweeper**: `vault-media-sweep` script and oneshot + timer,
   `ConditionPathIsMountPoint=/srv/blobs`, quiet period, copy and verify,
   stop-gap `refs`/`rewrite`, stub for orphans, delete. Dry-run constant
   set to true, so merging changes nothing.
5. **hook-fix**: unrelated rider. `.claude/hooks/worktree-create.sh` copies
   `.claude/hooks` into the new worktree with `cp -R`; the worktree already
   has that tracked directory, so cp nests a copy inside it as
   `.claude/hooks/hooks/`. Copy contents without clobbering instead.

The dry-run flip is a one-line follow-up after the manual steps, not part
of this PR.

### Dendritic placement

Rules from `nix/CLAUDE.md`: every file under `autoimport/` is a flake-parts
module; a feature owns one file and contributes to
`flake.modules.<class>.<role>`; settings that belong to a service defined
elsewhere are merged from the feature file, not added to the other file;
no new `jl.*` option for a knob only one file reads (`sweepDryRun` is a
`let` constant); `_`-prefixed paths are data, never logic.

- **ts-serve** goes in `autoimport/modules/proxy.nix`, `homeServer` block.
  It is the TLS front for the nginx that file owns and hardcodes nginx's
  port; that makes it the proxy aspect, not the tailscale aspect.
  `tailscale.nix` stays a `base` module.
- **blob-store and sweeper** join the existing vault durability module,
  which is renamed `autoimport/modules/obsidian.nix`: one feature file for
  everything the server does to the vault (autocommit, media sweep),
  `flake.modules.nixos.homeServer`. It contributes the tmpfiles rule, the
  nginx location (same merge pattern syncthing.nix and home-assistant.nix
  use on `services.nginx.virtualHosts.${host}.locations`), the sanoid entry
  `services.sanoid.datasets."tank/blobs"` (merged into backups.nix's sanoid
  config by the module system; backups.nix is not edited), and the sweeper
  service and timer. No new `jl.*` option: options are for sharing between
  files, and nothing else consumes this. Dry-run is a `let`-bound constant
  in the module, flipped by editing it. Its header comment grows to cover
  both units.
- **The script** is `autoimport/modules/_obsidian-media-sweep.py` next to
  its module: nix/CLAUDE.md says non-module files under `autoimport/` carry
  the `_` prefix, and the Python siblings (`odyssey-watch/_watch.py`,
  `graphical/_kitty-auto-pad.py`) do. Built with `writePython3Bin` and
  wrapped by `writeShellApplication` so the vault and store paths have one
  home (the module's `let`) and the tool is on PATH for hand runs. It is
  single-use and service-bound, so not an `autoimport/packages/` derivation.
- **The proposal** stays under `nix/proposals/`, which import-tree never
  sees.

Manual steps, in order:

1. `zfs create -o mountpoint=/srv/blobs tank/blobs && chown jeanluc:users
   /srv/blobs`, before deploying. A fresh dataset root is root-owned and
   tmpfiles only re-applies ownership when its rule set changes.
2. After deploy: copy one PNG and one `.m4a` into `/srv/blobs` by hand,
   embed both URLs in a scratch note, open it on the phone. HTTPS check and
   voice-memo go/no-go in one, before the sweeper does anything.
3. Media globs into the vault's `.gitignore`.
4. Sweeper dry run over the existing 68M; read the rewrite diff, the
   skipped list, and the would-be stubs; trash junk.
5. Flip dry-run off.

Revert points: ts-serve reverts by removing the unit and running
`tailscale serve reset`. blob-store is inert. sweeper reverts by flipping
dry-run back on or disabling the timer; blobs already moved stay valid
because the store keeps serving them, so a partial run breaks nothing.

Later: when vault-cli-headless ships its `mv`, replace the stop-gap behind
the `refs`/`rewrite` seam and delete the regexes.

## Open questions

- Quiet period length. 10 minutes is a guess.
- Whether `vault-autocommit` and the sweeper share one timer and ordering,
  or stay independent. With gitignore in place ordering does not matter.
- Which media extensions count. Start with image, audio, video, pdf.

## Sources

- Obsidian embeds help (external images only): https://obsidian.md/help/embeds
- Obsidian mobile blocks http external content: https://forum.obsidian.md/t/external-images-over-http-dont-load-on-android-preview/27000
- External PDF embed does not render: https://forum.obsidian.md/t/embed-pdf-from-web-url/81773
- Custom Image Auto Uploader: https://github.com/haierkeys/obsidian-custom-image-auto-uploader
- S3 Image Sync: https://github.com/jongchoiyip/s3-image-sync
- Attachment Uploader (desktop only, shell command): https://github.com/zhuxining/obsidian-attachment-uploader
- Garage design goals: https://garagehq.deuxfleurs.fr/documentation/design/goals/
- Garage configuration reference: https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/
- NixOS services.garage module: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-servers/garage.nix
- Sibling proposal, link rewriting: `nix/proposals/vault-cli-headless/PROPOSAL.md`
- Prior state and topology: `nix/mdfiles/obsidian-sync-proposal.md`

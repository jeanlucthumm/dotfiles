# Flake-parts migration: parity gaps vs `master`

## High severity (live functional drops)

### H3. jeanluc `hashedPassword` dropped on all NixOS hosts

Master `system/modules/user-jeanluc.nix:25` set it; `autoimport/modules/jeanluc.nix:23`
is a bare `# TODO use hashedPasswordFile` → no password on desktop/server/server-mini.
Restore (or move to a `hashedPasswordFile` via agenix). Hash from master:

```
hashedPassword = "$y$j9T$olPxnw3sjt6/HFw.1SKyT/$GVqznhguvSLErdAQxNW0O6CKxVuUc6trVrxvj2pJLw1";
```

### H4. `server-mini` hostId collides with `server`

`autoimport/modules/hosts/server-mini.nix:9` is `1d9f895e` — the SAME as `server`
(`server.nix:14`). Two ZFS hosts must not share a hostId (server-mini is the
replication receiver). Master server-mini used `3333bb65`. Set it back.

### H-neo4j. Dangling `get-key-neo4j` (neo4j dropped — clean it up)

`autoimport/packages/_derivations/graphiti-mcp-server.nix:71` wraps with
`export NEO4J_PASSWORD=${NEO4J_PASSWORD:-$(get-key-neo4j)}`, but `get-key-neo4j` is
defined nowhere (it came from the dropped `system/modules/secrets.nix`). Since neo4j
is being dropped: remove that `--run` line, and leave `graphiti-mcp-server`
**uninstalled** (it needs a neo4j backend — don't add it back to `home.packages`).

______________________________________________________________________

## Medium severity

### M1. Dropped system services (`foundation.nix` → all NixOS hosts)

Master `system/modules/foundation.nix` enabled these on every NixOS host; autoimport
dropped them. Re-add to `flake.modules.nixos.base` (`base.nix`) for parity:

- `services.upower.enable = true;` (foundation.nix:50)
- `services.udisks2.enable = true;` (foundation.nix:52) — **note:** `security.nix:34-37`
  still has udisks2 polkit rules that currently govern a disabled daemon.
- `services.avahi` with `nssmdns4 = true; nssmdns6 = true;` (foundation.nix:18-23) —
  `.local` discovery (reaching `server.lan` etc.). Currently only on the `iso` host.

### M2. `services.flatpak.enable` dropped (desktop)

Master `system/hosts/desktop/default.nix:73`. Add to the graphical nixos slot or
directly in `autoimport/modules/hosts/desktop.nix`.

### M3. `server-mini` hardware tuning lost (3 GB RAM box)

Master `system/hosts/server-mini/default.nix`:

- ZFS ARC caps (`boot.kernelParams = ["zfs.zfs_arc_max=536870912" "zfs.zfs_arc_min=268435456"]`,
  lines 3-7) — **without these ARC defaults to ~half RAM and can OOM.**
- swap 4 GiB (autoimport has 8 GiB — `server-mini.nix:15`).
- `smartmontools` (line 25) — absent.
- ZFS scrub timers: master imported `modules/zfs.nix` here; autoimport's scrub lives
  in the `homeServer` slot which server-mini does NOT import. Decide whether to import
  a scrub slot or inline the timers.

### M4. headless hosts lost `notify` / `ffmpeg` / `usbutils`

Master had these via `cli/qol-system.nix` (server imported full `cli`). autoimport
moved them into `flake.modules.homeManager.graphical`
(`graphical/graphical.nix:101-106`), which server/server-mini don't import. Move
`notify`/`ffmpeg`/`usbutils` into a non-graphical home slot (e.g. the base cli
profile) so headless hosts regain them. (`copy-last-cmd` is kitty-based — fine to
leave graphical-only.)

### M5. macbook lost podman stack + deploy-rs

Master `system/hosts/macbook/default.nix:32-39`: `podman`, docker→podman shim,
`podman-compose`, `podman-tui` (autoimport darwin dev only has `qemu`). Also
`deploy-rs` is in the nixos `base` slot only (`base.nix:44`), not darwin, so macbook
lost it too. Add a darwin packages block (decide: per-host on macbook, or darwin
dev/base slot).

### M6. server HM lost `claude-code` + `reddit-easy-post`

Master `home/hosts/server.nix:8-19` installed both into jeanluc's profile. autoimport
server imports nixos `base`+`homeServer` only; `claude-code` lives in the `dev` HM
slot (`llm.nix`) which server never pulls; `reddit-easy-post` is commented at
`autoimport/modules/hosts/server.nix:46-49`. Add them to the server HM block. (The
old `~/restore.sh` user file became the system `restore-backups` script — arguably
fine; decide if you still want the user-facing copy.)

### M-task. taskwarrior GCP sync hard-requires the agenix secret

`autoimport/modules/taskwarrior.nix:51` does
`credential_path = config.age.secrets.taskwarrior.path` unconditionally. Any host
that pulls the `dev` slot without the secrets module (cloud-vm; also a concern for any
secret-less dev host) fails with `attribute 'age' missing`. Guard it, and while
you're there collapse the duplicated `config = {…}` blocks (lines 25 & 45) into one:

```nix
# in let: hasTaskSecret = (config ? age) && (config.age.secrets ? taskwarrior);
sync = { encryption_secret = "not-required"; }
  // lib.optionalAttrs hasTaskSecret {
    gcp = { bucket = "taskwarrior-23423478"; credential_path = config.age.secrets.taskwarrior.path; };
  };
```

### M-dictation. NixOS VAD keybind commented out

`autoimport/modules/dictation.nix:526` — `Mod+Shift+O → toggle-vad` is commented
(and the niri import at :517). The `toggle-vad` binary is installed but unreachable by
hotkey. Re-enable once H1 (niri) is done. (Darwin push-to-talk/VAD hotkeys are fine.)

### M-syncthing. HM syncthing → system syncthing (scope change)

Master enabled syncthing in the user's HM on desktop (`home/modules/syncing.nix`).
autoimport enables it system-wide for all NixOS hosts (`base.nix:86`, with its own
`# TODO reconcile`). Functionally runs, but data-dir/user-service semantics differ.
Decide intended scope and resolve the TODO. (Server's host-specific syncthing is
fully ported and unaffected.)

______________________________________________________________________

## Low severity

- **L1. fish integration flags dangle.** With fish retired, remove
  `shellIntegration.enableFishIntegration` (kitty, `graphical/graphical.nix:126`) and
  `programs.starship.enableFishIntegration` (`graphical/starship.nix:10`).
- **L2. yazi `c y` keybind dropped.** Master `cli/qol.nix:99-103` had a 5th yazi
  keymap (copy file contents to clipboard via `clip`); autoimport `cli.nix:92-115`
  has 4. Re-add (`clip` still exists).
- **L3. dead/duplicate nushell slot.** `autoimport/modules/nushell/nixos.nix` defines
  `flake.modules.homeManager.nixos` (nothing imports it) with an older `nrs`/`nra`
  lacking the delock guard. The live versions are in `nushell.nix`. Delete
  `nushell/nixos.nix`.
- **L4. authorizedKeys trims.** desktop no longer sets jeanluc `authorizedKeys`
  (master set it for all hosts via `user-jeanluc.nix:23`); macbook dropped the
  `server` pubkey (`macbook.nix` vs master `macbook/default.nix:72-78`). Confirm
  intent; restore if you SSH into those.
- **L5. xkb `us` not on servers.** Master `foundation.nix:42-45` set
  `services.xserver.xkb` on all hosts; autoimport only in graphical slot. Low impact
  (console keymap is separate). Move to base or accept.
- **L6. LS_COLORS reimplemented.** Was a hand-rolled base16 map
  (`home/modules/ls-colors-hack.nix`), now `vivid generate` in
  `theme/home.nix:116-141`. Intentional-looking; just verify the `vividTheme` mapping
  covers every configured theme (it `throw`s on an unknown one).

______________________________________________________________________

## Deferred / blocked (intentional or needs external deps)

- **moltbot/openclaw** — staying off (upstream broken). Orphans to clean up *when you
  reinstate it*: the `moltbot-telegram.age` / `moltbot-anthropic-token.age` files +
  their `_age/secrets.nix:12-13` recipients (currently no consumer), and the
  `openclaw-backup` job + `/var/lib/openclaw` tmpfiles in `storage/backups.nix:106-130`
  (backs up a dir nothing produces). The `nix-openclaw` flake input is still declared
  but unused. Port target: a new `flake.modules.nixos.*` importing
  `inputs.nix-openclaw.nixosModules.openclaw`, the two age secrets owned by the
  openclaw user, `services.openclaw.*`, and the `memory-flush-prompt.md` +
  `skills/guided-day/SKILL.md` files (referenced via `readFile`/`source`).
- **server agenix / `age.identityPaths`** — coupled to moltbot. The server imports
  no `secrets` slot, so `age.*` options don't even exist there (setting
  `identityPaths` errors until the slot is imported). There's currently no live secret
  consumer on the server (moltbot deferred, neo4j dropped), so leave it commented at
  `server.nix:17`; restore (`["/home/jeanluc/.ssh/id_ed25519"]` + import `secrets`
  slot) together with moltbot.
- **macbook-work** — see E2; blocked on the `dotfiles-private` input + username
  decision.
- **taskwarrior `cora-*` / `job-anthropic` contexts** — master had 8 context labels
  on personal hosts (`taskwarrior/default.nix:8-17`); autoimport keeps only
  `nix`/`chore`. Likely retired or moved to `dotfiles-private.homeModules.work`
  (couldn't verify — not checked out). Confirm: re-add to `taskwarrior.nix` if
  personal; else verify work-private defines them and wire it in macbook-work.

______________________________________________________________________

## Dead-on-master (NOT gaps — imported by zero hosts on master, safe to ignore)

- `system/modules/speech-to-text.nix` (ROCm whisper) — commented out in
  `dictation.nix:6-44`; was never imported by any host.
- `home/extra/aichat.nix` — a `programs.aichat` module never enabled anywhere
  (the `aichat` *package* is preserved in `llm.nix:25`).

______________________________________________________________________

## Suggested order

1. Eval-breakers E1, E2 (so the flake evaluates).
2. H1 (WM sessions — biggest functional impact), H3 (password), H4 (hostId).
3. H2, H-neo4j, M-task (package/secret correctness).
4. M1–M6 (service/package restores).
5. Low + deferred as you get to them.

Validate each host with:
`nix eval --raw '.#nixosConfigurations.<host>.config.system.build.toplevel.drvPath'`
(and `.#darwinConfigurations.<host>...` / `.#homeConfigurations."developer@cloud-vm".activationPackage.drvPath`).
`nix flake check` does NOT cover homeConfigurations.

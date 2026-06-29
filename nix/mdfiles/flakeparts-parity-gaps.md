# Flake-parts migration: parity gaps vs `master`

## Medium severity

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

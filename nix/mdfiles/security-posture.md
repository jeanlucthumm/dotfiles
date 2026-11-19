# Security Posture

How the machines and accounts behind this repo are meant to be secured, and why. This is the target: not every piece is in place at any given moment, and the list of gaps is kept privately, not here.

Rewritten 2026-11 from first principles. The earlier version centred on secrets and SSH keys held in YubiKeys; "Not doing" records what was dropped.

## Threat model

> Assume any box will at some point run hostile code as me, through a bad package or a misled agent. That should cost one box and an afternoon of rotation. It should never cost a root account, never reach work, and never lock me out.

**Defend against**

- Untargeted malware in a package, extension or MCP server.
- An agent misled by something it read, or simply wrong.
- Phishing of a root account.
- Loss or theft of a device or key.

**Accept**

- A compromised box loses everything on it. The fix is rotation, not prevention.
- The server is me, and an agent on a box is me on that box.
- A targeted attacker who has studied this setup is out of scope.

**Rules everything else follows from**

1. Changing a root account's security takes a physical approval from me. Nothing on a box can do it alone.
2. A compromised box doesn't reach other boxes, or work, without me acting.
3. A lost device or key costs only a replacement.
4. Phishing can't take a root.

## Roots

A root is an account that can take over other things while nothing else can recover it. An API key is not a root: lose it and you rotate it from the provider. Lose the provider account and there is nothing above it to rotate from.

| Root | What falls with it |
|---|---|
| Email, and the registrar of its domain | Password resets for most other accounts; Tailscale signs in through it |
| GitHub | The repos every machine builds from |
| Password manager | Every login stored in it |
| claude.ai | Remote-control sessions on the server, plus the mail, calendar and Drive connectors |
| Apple account | The phone, which is itself a root factor |

| Tier | Guarded by |
|---|---|
| Roots | A hardware key or the phone. Never a passkey stored in the password manager. |
| Everything else | Passkeys and passwords in the password manager |

The password manager is unlocked on the boxes, so anything in it counts as being on a box, and a root whose passkey lived there would fall with the box. A hardware key's secret is never on any box. The phone runs neither packages nor coding agents, and it shows what is being approved.

Sites an agent signs in to are the exception to passkeys: they keep a password plus a one-time code, because an agent can't use a passkey stored in the password manager.

Each root has several independent factors, so losing any one thing still leaves a way in. Paper recovery codes cover losing everything at once.

## Hardware keys

Hardware keys do one job: logging in to roots, plus SSH from the boxes I sit at. They no longer decrypt secrets.

| Key | Lives |
|---|---|
| USB-A security key | Desktop |
| Nano | Macbook |
| USB-C | Safe |
| Nano | A second laptop |

- **What a touch proves:** that I am physically there. It doesn't prove what I'm approving, so it stops silent, automatic abuse and not a trick aimed at me.
- **A lost key** is removed from the roots using another key, then replaced. It holds a handful of logins and nothing else.
- **A key stolen along with its box** is still only half a login. Every root also needs a password or the key's PIN, and the disk has its own passphrase.

## Disk encryption

Unencrypted, a stolen box is a breached box. The unlock method follows one rule: a box holding logged-in root sessions needs a secret only I know at boot, and a box holding only rotatable things may unlock itself.

| Box | Unlock | Why |
|---|---|---|
| Macbook | FileVault | Holds browser sessions |
| Desktop | Passphrase, at the keyboard or over SSH in early boot | Holds browser sessions; SSH entry allows remote wake |
| Server | TPM auto-unlock for the OS drive; the data pool has its own passphrase | Must boot unattended and holds only rotatable things |
| Macmini | FileVault, no auto-login | Holds a signed-in Apple account |

TPM unlock without Secure Boot stops a pulled or discarded drive and a casual thief. It doesn't stop a skilled thief who takes the whole server. That is accepted: a stolen server is treated as breached and rotated.

The disk passphrase is deliberately separate from the hardware key, so stealing a box together with its key opens nothing.

## SSH

| From | To | Credential |
|---|---|---|
| Macbook | Desktop, server, macmini | Hardware key |
| Desktop | Server | Hardware key |
| Phone | Desktop, server, macmini | Software key |
| Server | Itself and GitHub | File key |
| Macmini | Nothing | None |

1. **Downhill only.** Macbook, then desktop, then server. Nothing lower reaches back up. If the server ever needs the desktop's GPU, that goes through a purpose-built service with its own auth, not SSH.
2. **Hardware where I sit, files where I don't.** A file key can be copied once and used from anywhere until someone notices. A hardware key only works while the attacker is still on the box, which shrinks how much depends on detection.
3. **The list lives in nix** (`secrets/_pubkeys.nix`). Hand-added keys are stopgaps.

One touch opens a connection that is reused for a few hours. That is fine because access only flows downhill: whoever owns the higher box already has the better prize.

## GitHub and tokens

- Every box pushes as me, the server included. No bot account and no deploy keys.
- Tokens on boxes carry no account-admin scopes, such as adding SSH or signing keys. Account admin happens in the browser, where the hardware key gates login and sensitive actions.
- Machines rebuild from the dotfiles repo only when I run the rebuild, so a bad push needs me to act before it lands anywhere.

## Agents

An agent on a box is me on that box. What matters is where agents reach beyond it.

| Kind | Needs | Doesn't need |
|---|---|---|
| Lifestyle, on the vault | Vault read and write, mail, calendar, Drive | sudo, `gh`, SSH keys, repos |
| Coding | Worktrees, a shared repo area, `gh` push, vault read | Mail, calendar, Drive, vault write |

Each kind handles one sort of untrusted input and lacks the other's power. The one that reads strangers' text can't push code, and the one that runs strangers' packages can't read mail.

The split is a guard rail enforced through agent settings, not a wall. It stops a misled agent. Hostile code on the same box runs as me regardless.

- **Outward mail actions** (send, forward, trash) are denied unless a job needs them.
- **Connectors follow the account.** Anything attached to claude.ai is available on every box signed in to it, which is one more reason claude.ai is a root.
- **The vault must stay data.** Obsidian runs plugin code, so its `.obsidian` folder syncs as a separate Syncthing folder that the server is not part of, and no plugin that executes note content is installed. Agents in the vault run on the server only.
- **Package-heavy work belongs on the server**, which has no browser sessions.

## Secrets

- **Server:** agenix, decrypted with the server's SSH host key. The server must boot unattended, so its secrets are readable on the box by design. They are all rotatable.
- **Hardware keys are out of this path.** Decrypting with a key added a touch and a failure mode without protecting the plaintext afterwards.
- **Agent website logins:** on trial, see [the proposal](agent-website-logins-proposal.md). The agent asks for a login, I approve it in the password manager's app, and it is filled straight into a hosted browser for the next 30 days. Neither the server nor the model ever holds the password.
  - Roots, and anything that can reset one, sit in a separate vault that can't be asked for.
  - If adopted, this is a deliberate exception to "a breach costs one box": a breached server can also use the logins I approved in the last 30 days.
  - Fallback if the trial fails: a service account scoped to one dedicated vault of low-value logins.
- **Open:** how workstation API keys are delivered, by agenix with a host key or straight from the password manager.

## Noticing

Watch at the accounts, not on the boxes. A breached box can't be trusted to report on itself, and the damage that matters happens when stolen things are used somewhere else, where the providers already watch.

1. Sign-in, new-device and new-key alerts on every root, arriving as mail on the phone.
2. Spend caps and alerts on API keys.
3. A decoy credential on each box that nothing legitimate uses. Any use raises an alert naming the box.

Nothing here catches an agent quietly reading what it is allowed to read. The rules bound that; detection doesn't.

Rotation is worked out on the day. Roots are what everything else is rotated from, which is why they must survive losing any box.

## Not doing, and why

| Idea | Why not |
|---|---|
| Secrets decrypted by a hardware key | It guards rotatable keys whose plaintext is readable anyway, and it was the part that broke when a key was lost |
| Containers for dev work | The rules hold without them, and the server already is the place with no browser sessions |
| Bot account or deploy keys for the server | The server being me is accepted |
| Secure Boot for the TPM unlock | Extra machinery against an attacker who is out of scope |
| On-box intrusion monitoring | Noisy, and it runs on the box that isn't trusted |
| Separate users per agent kind | The guard rail is enough for now |

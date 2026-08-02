# Agent Farm — Product Requirements

Status: **draft, requirements only.** No technology is chosen here. The candidate
survey in [Open Decisions](#open-decisions) is the next piece of work.

## Vision

A permanently-running system at home that I delegate software work to. From my phone or
laptop I describe a task against one of my projects; an agent picks it up, works
autonomously in an isolated environment, and comes back with a draft PR. I check in when
I feel like it — reviewing, steering, or ignoring it until tomorrow. The farm is the
thing that turns "I should fix that" into a reviewable diff without me opening a laptop.

The differentiator over hosted products (Devin, Codex cloud, Claude Code on web) is that
it runs on hardware I own, against private repos, with my Nix toolchains, and — critically
— with access to a **macOS/iOS build environment** that no hosted vendor gives me.

## Substrate that exists today

| Node | Platform | Availability | Role in the farm |
|---|---|---|---|
| `server` | x86_64-linux, NixOS | always on | primary Linux compute; ZFS |
| `server-mini` | x86_64-linux, NixOS | always on | secondary Linux compute |
| Mac Studio | aarch64-darwin | always on | **not yet in the flake** — Xcode/iOS/codesign work |
| `macbook` / `macbook-work` | aarch64-darwin | intermittent | client, not compute |
| `desktop` | x86_64-linux, NixOS | intermittent | client; occasional burst compute |
| `cloud-vm` | x86_64-linux, NixOS | — | existing off-site node |

Relevant existing plumbing: agenix secrets, deploy-rs, a `phone` SSH pubkey already
enrolled on server hosts, flake-parts + import-tree module layout, jj (not git) as the
VCS with a 1-PR-per-commit workflow.

**Gap:** the Mac Studio has no host entry in this flake. Onboarding it as a
`darwinConfiguration` is a prerequisite for anything below, independent of harness choice.

## Modes of use

1. **Away (phone).** Low-bandwidth. Dispatch a task, read a summary, approve/reject,
   review a PR, unblock an agent that asked a question. No terminal.
2. **At the laptop.** Full review, interactive steering, taking over a session by hand.
3. **Asleep.** Long autonomous runs — the reason the farm exists rather than just running
   agents in local terminals.

## Core loop

```
dispatch ──► agent claims a workspace ──► works autonomously ──► draft PR
   ▲                                            │                    │
   │                                       needs input? ──► notify ──┘
   │                                            │                    ▼
   └────────────── "address the comments" ◄──── me, reviewing on GitHub mobile
```

The PR is the delivery unit and the review surface. That is deliberate: GitHub's mobile
app already solves mobile diff review, threaded comments, and notifications, and I already
live in that workflow. The farm should not build a review UI.

---

## Requirements

### P0 — the thing does not exist without these

| # | Requirement | Acceptance |
|---|---|---|
| R1 | **Dispatch from mobile.** Start a task against a named project with a free-text prompt, from a phone, off the home network. | Task starts within seconds of sending; no terminal, no VPN gymnastics beyond an always-on mesh. |
| R2 | **Autonomous execution.** The agent runs to completion without me babysitting, including long (>1h) runs. | A task dispatched at 11pm has a draft PR by morning. |
| R3 | **Workspace isolation.** Concurrent agents cannot see or clobber each other's files, nor my working copies. | N agents on the same repo simultaneously produce N independent diffs. |
| R4 | **Heterogeneous placement.** A task declares what it needs (`linux` / `darwin+xcode`); the farm runs it somewhere that satisfies it. | An iOS task lands on the Mac Studio; a backend task lands on Linux; I never specify a hostname. |
| R5 | **Reproducible per-project environment.** Each project's toolchain comes from its flake, not from hand-installed junk on the host. | A fresh workspace builds and tests the project with no manual setup. |
| R6 | **PR as output.** Draft PR, one commit, pushed to a branch — matching the existing jj workflow. Never pushes to `main`, never merges. | Output is reviewable in the GitHub mobile app. |
| R7 | **Review feedback round-trip.** My PR comments become the agent's next instruction; it amends the same commit and force-pushes. | "Address review comments" needs no copy-paste from me. |
| R8 | **Blocked-agent notification.** When an agent needs a decision or credential, it pushes a notification I can act on from the phone. | No agent silently burns an hour waiting, and none silently guesses on a one-way door. |
| R9 | **Secrets isolation.** Agents get model API keys and a scoped GitHub token; they do not get my SSH keys, my YubiKey, or other projects' secrets. | Compromised agent ≠ compromised homelab. |
| R10 | **Survives restarts.** Farm comes back after a power cut or `nixos-rebuild` without losing the task queue. | Reboot mid-task; task is either resumed or cleanly re-queued and I'm told which. |

### P1 — needed before I trust it with real work

| # | Requirement |
|---|---|
| R11 | **Observability.** What's running, on what, for how long, current step, live log tail. |
| R12 | **Cost & quota visibility.** Per-task and per-day token spend; a ceiling that stops the farm rather than surprising me. |
| R13 | **Kill switch.** Terminate a wedged agent and reclaim its workspace without restarting the farm. |
| R14 | **Ephemeral capacity.** Spin up throwaway VMs/pods on demand for parallel or hostile workloads, and reap them. |
| R15 | **Network blast radius.** An agent reaches its repo, package registries, and model APIs — not my LAN, not Home Assistant, not the NAS. |
| R16 | **Declarative config.** The farm is defined in this flake. No state that only exists because I clicked something in a web UI. |
| R17 | **Multi-agent per task.** Run N attempts and pick a winner (see `llm-tourney.md`, which specs this independently). |

### P2 — later

Self-hosted/local models for cheap tasks · scheduled recurring jobs (dependency bumps,
flake.lock updates) · agents that file their own issues · non-code work (research, docs)
· sharing the farm with anyone else.

### Non-goals for v1

Autonomous merging to `main`. A custom code-review UI. Multi-user/tenancy. Hosted cloud
fallback when home is down. Replacing my interactive laptop Claude Code usage — the farm
is for delegated work, not for pair programming.

---

## Constraints and one hard truth

**Kubernetes cannot schedule macOS workloads.** There is no such thing as a macOS
container; macOS isolation is virtualization-only (Apple's Virtualization.framework, via
tart/Lume/UTM), and Apple's licence caps you at 2 macOS VMs per physical host. So the
plan as stated — "k8s provides the resources including Darwin and the agent isolation" —
only works for half the fleet. Realistically the farm is:

- **Linux side:** real containers/pods. Cheap, dense, fast to create, genuinely isolated.
- **Darwin side:** a *runner pool*, not a scheduler target. Either 1–2 long-lived macOS
  VMs on the Mac Studio, or agents running as separate users on the host, registered with
  the control plane as external workers. Expect 2 concurrent iOS tasks, not 20.

That asymmetry is the single most important design fact in this project, and it should
drive harness selection — whatever I pick must tolerate a worker pool that isn't
homogeneous and isn't all under one orchestrator.

Two smaller ones:

- **k8s on two boxes is a want, not a requirement.** Nothing in R1–R17 requires it; NixOS
  containers, systemd units, or plain Docker + a queue would satisfy the Linux side with
  far less machinery. I want to run it as a learning exercise, which is a fine reason —
  but it should be recorded as a *preference* so that if it fights the design I can drop
  it without re-deriving the requirements.
- **jj, not git.** Most orchestrators hardcode `git worktree`. jj-colocated repos are
  git-compatible on disk, so this is probably fine, but it's an explicit compatibility
  check for any candidate.

---

## Open decisions

These are the questions the next work item answers. Candidates below are from a shallow
survey — **none of this is verified**, and this category churns badly (Crystal deprecated
Feb 2026, Vibe Kanban's company shut down Apr 2026 and it's now community-maintained), so
maintainer health is a selection criterion, not a footnote.

**D1 — Which agent harness?** The thing that runs the loop and edits code.

| Candidate | Shape | Why it might win / lose |
|---|---|---|
| **Pi** (`earendil-works/pi`) | OSS TS harness; RPC + SDK modes are first-class | Built for server-side/headless operation; provider-neutral. **No built-in permission system** — needs external sandboxing, which the container story already provides |
| **Claude Code headless** (`claude -p`, background jobs) | What I already use and pay for | Zero new harness to learn; already has worktree isolation and background-job semantics. Weakest on "is it designed to be a fleet" |
| **OpenCode** | OSS, broad provider support | Alternative to Pi if Pi's ergonomics disappoint |
| **OpenHands** | Sandboxed autonomous SWE agent | Closest to "autonomous" out of the box; heavier, more opinionated |

**D2 — Which control plane?** Queue, dispatch, state, and the mobile surface.

| Candidate | Notes |
|---|---|
| **Linear** (leading) | Free tier includes API, webhooks **and the agent platform**. Delegating = assigning an issue to the agent, which fires an `AgentSessionEvent`; follow-up comments arrive as `prompt` activities. Gives R1/R7/R8/R11 off the shelf plus a real mobile app. See note below |
| **Paseo** | Self-hosted mobile + desktop app for Pi; directly targets R1/R11. Pairs with D1=Pi |
| **Vibe Kanban** | Task board + web UI, worktree-per-task, agent-agnostic. Community-maintained now |
| **Sculptor** | Container-per-agent rather than worktree-per-agent — aligns with the Linux isolation model |
| **Roll my own** | A queue + a Telegram/Slack bot. Most control, most work, best jj fit |
| **Conductor** | macOS desktop app — wrong shape (client, not always-on server), but possibly useful on the Mac side |

> **Linear notes** (verified against linear.app/pricing, July 2026). Free: 2 teams,
> 250 *non-archived* issues, 10MB uploads, API + webhooks + agent platform included.
> Basic $10/user/mo removes the issue cap. For a solo operator the free tier is
> sufficient, with two caveats: (1) the 250 cap is enforced hard — issue creation blocks
> with no grace period — so an auto-archive-on-close policy is a *prerequisite*, not
> cleanup, especially if agents file their own tickets; (2) the 2-team limit is avoided
> by using one team with a project per repo, since projects are unlimited.
>
> Two integration constraints: agents need a **publicly reachable webhook URL** with a
> **5-second response budget**. That means inbound ingress (Cloudflare Tunnel / Tailscale
> Funnel) — the first requirement that punches a hole in R15. Mitigated by keeping the
> receiver a thin ack-and-enqueue shim that never exposes the farm itself.
>
> Claude Code has no official Linear agent integration; **Cyrus** (OSS) connects Claude
> Code to Linear's Agent SDK and is a candidate answer to D1 and D2 simultaneously.

**D3 — Linux isolation mechanism.** k8s (k3s?) vs NixOS containers vs Docker + queue.
Downstream of D1/D2; don't decide first.

**D4 — Darwin execution model.** tart VMs vs multi-user on the host vs a
GitHub-Actions-style self-hosted runner on the Mac Studio.

**D5 — Remote access.** Presumably Tailscale, given a `phone` key is already enrolled.

### Recommended order

1. Onboard the Mac Studio into the flake as a `darwinConfiguration` — unblocks everything,
   valuable regardless of every other decision.
2. Answer **D1** with a spike: run one long autonomous task headlessly on `server`, produce
   a real draft PR on a real project. This tests R2/R5/R6 and kills the most uncertainty.
3. Answer **D2**, then **D3/D4**.

## Done looks like

From a coffee shop, on my phone: I read a Slack-style message that an agent finished, open
the PR in the GitHub app, leave three comments, reply "address these", and close my phone.
The next notification says the PR is updated. I never opened a laptop, and the change
compiled against my real toolchain — including, when the project is an iOS app, a real Xcode.

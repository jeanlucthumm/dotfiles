# Agent Website Logins Proposal

Status: **draft, 2026-11-18. Waiting on a trial.** Evidence, sources and the alternatives live in [the research](../proposals/1password-agent-credentials/RESEARCH.md); this doc holds only the plan.

## Goal

The chore agent on `server` drives a hosted Kernel browser and must sign in to websites unattended. Three requirements:

- No root login is ever reachable from the server.
- The model never handles a password.
- A breach costs a rotation, not an account.

## Proposal

Use **1Password Agentic Autofill through Kernel**. The agent asks for a login; I approve it once in the 1Password app; for the next 30 days the 1Password extension inside the Kernel browser fills it whenever the agent is logged out. The password and TOTP code go from 1Password straight into the page. Neither the server nor the model ever holds them.

Kernel is the only browser provider where this works on a personal account: it supplies the 1Password app registration that everyone else makes you bring from a 1Password Business account.

## The exception to the threat model

The rule says the server reaches only a fixed, narrow set of low-value logins. This proposal replaces it with:

> The server may **ask** for any non-root login. It may **use** one for 30 days after I approve it.

Why that is acceptable:

- **Roots can't be asked for.** Agentic Autofill grants only from the Personal/Private vault. Roots, and anything that can reset them (mail, phone carrier, domain registrar), move to a separate vault, so they are never offered.
- **Every new login needs my approval.** There is no silent new access, and the prompt shows the site and the agent's stated reason.
- **On a breach,** the loss is the passwords of logins approved in the last 30 days, plus their sessions. TOTP seeds never leave 1Password.
- **Nothing 1Password-related sits on the server.** Its only secret stays the Kernel API key.

## Day to day

- Most chores need no prompt: the saved browser profile is still logged in.
- When a site has logged the agent out, it fills the login itself if its approval is under 30 days old.
- **Monthly renewal.** The agent tracks approval dates itself, because Kernel doesn't report expiry. Before approvals lapse, it sends one request covering up to 5 sites and posts the link in chat. Expect about 1–2 prompts a month, at a time that suits me.
- A site never approved, or approved more than 30 days ago, gets a one-off prompt mid-task.
- Every ~90 days: reconnect Kernel to 1Password (sign-in and consent on 1password.com).
- Email or SMS codes still come to me, as today.

## Setup

1. **1Password:** Individual or Families account on 1password.com (US region). Create a `Roots` vault and move the root logins into it.
2. **Kernel:** connect the 1Password account once, from the agent's chat or the Kernel API, approving the consent page myself.
3. **Chore agent skill** (lives in the vault, not this repo). Rewrite the login hand-off in `kernel-browser`:
   - Reuse an approved login if one exists; otherwise create a request.
   - Post the approval link in chat and wait. Never put the link in notes.
   - Fill on the login page itself, once per page for multi-step logins.
   - Never retry a fill automatically, because a fill submits the form.
   - Keep a dated list of approvals and renew them monthly in one batch.
   - Fall back to today's log-in-on-the-phone hand-off when a fill fails.
4. **This repo:** nothing required. The Kernel API key's target delivery (an agenix secret outside synced folders) is described in the research.

## Trial before adopting

Run it for a couple of weeks on low-value sites. Go/no-go checks:

| Check | Why it matters |
|---|---|
| Tapping an approval link on the iPhone opens the 1Password prompt | Chores are mostly started from the phone. 1Password's developer docs say approving on mobile is still "in development"; their consumer page says it works. |
| A login in `Roots` is not offered in the prompt | The exception depends on it |
| A fill works in a headless browser | Headless is the agent's default |
| Kernel's item events record each fill | The only usage log available on a personal plan |
| Prompts actually stay around 1–2 a month | The UX case |

**If the iPhone check fails**, don't adopt yet. Use the fallback from the research instead: a 1Password service account scoped to one dedicated vault, with its token held by Kernel. That needs no taps but keeps passwords and seeds at Kernel.

## If the server is compromised

1. Delete every Kernel API key in the Kernel dashboard. This cuts off fills and sessions at once.
2. Disconnect the 1Password connection in Kernel. It can't be revoked from inside 1Password.
3. Rotate the passwords of logins approved in the last 30 days, and sign out their other sessions.

## Cost

1Password $3.99/mo (Individual) or $5.99/mo (Families), billed yearly. Kernel's free plan covers it: Agentic Autofill doesn't use Kernel's 3-site Managed Auth allowance, and a fill costs seconds of browser time.

## Open questions

- Will 1Password's planned shared-vault support make the `Roots` vault grantable? Recheck when it ships.
- Can the Kernel dashboard disconnect 1Password, or only the API?
- 1Password's developer docs call the API "partner preview", while Kernel calls it generally available. Expect some churn.

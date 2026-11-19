# 1Password credentials for the server agents: research

Date: 2026-11-18. Features and prices move monthly; every claim below is as of this date. Builds on [browser-use/RESEARCH.md](../browser-use/RESEARCH.md), which chose Kernel as the hosted browser.

Evidence tags: **[docs]** vendor docs, **[src]** read in source (vendor repo or the pinned nixpkgs), **[pricing]** vendor pricing page, **[inferred]** my reasoning, **[unverified]** a claim I could not confirm.

## Verdict

> **Follow-up (same day):** Agentic Autofill through Kernel is now the preferred option, if approving from the iPhone works. The plan and trial are in [the proposal](../../mdfiles/agent-website-logins-proposal.md); the evidence is in [Agentic Autofill in depth](#agentic-autofill-in-depth). The service-account setup below is the fallback.

**Create a 1Password service account that can read one dedicated vault, and give its token to Kernel. Put no 1Password secret on the server.**

Kernel's Managed Auth has a [1Password integration](https://www.kernel.sh/docs/integrations/1password): you paste a service-account token into the Kernel dashboard, and Kernel looks up the login by domain, signs in, and signs in again when the session expires, TOTP included, for any flow that needs no human step [docs]. The agent then opens a browser on a profile that is already logged in.

| Requirement | Result |
|---|---|
| Root accounts unreachable from the server | **Yes, structurally.** A service account can't be granted your Personal/Private vault, and its vault list can't be changed after creation [docs]. Root logins are simply not in the vault. |
| A server compromise costs only what's on the server | **Yes.** The server holds only the Kernel API key it already has. Assume that key can extract every password in the dedicated vault (see Risks) [inferred]. That is the allowed loss. |
| Boots unattended | **Yes.** Nothing 1Password-related runs on the server. |
| Revoke in one step from another machine | **Yes.** "Revoke Token" on 1password.com is immediate [docs]. |
| Detect misuse | **Weak.** See "Audit and alerting". This is the one requirement no option meets on an individual or family plan. |
| Model never sees the password | **Yes in normal operation**, not as a hard boundary. See "Can the model be kept away from the password?". |
| Simple | No Nix changes. Two dashboards, about 15 minutes. |

Cost: $4–6/mo for 1Password, plus $0 on Kernel's free plan for up to 3 sites or $30/mo beyond that. Details in [Pricing](#pricing).

If a site's session lasts for weeks, the current log-in-on-your-phone hand-off is already enough and exposes no password at all. Add this for sites that log you out often.

### Decisions for you

1. **Is it acceptable that Kernel holds a token that can read the agent vault, TOTP seeds included?** Kernel already holds the logged-in sessions for these sites. This adds their passwords and seeds to what a Kernel breach exposes. If no, use the fallback (token on the server), which costs more wiring and lets the model read passwords.
2. **Do TOTP seeds go in the agent vault?** With them, re-logins are fully unattended, and TOTP stops protecting against a Kernel or server compromise. Without them, you get a prompt at every re-login. I'd say yes for low-value sites.
3. **Or carve out an exception for Agentic Autofill?** See [Agentic Autofill in depth](#agentic-autofill-in-depth). It hinges on whether approving from the iPhone works; test that first.

---

## Recommended setup

None of this touches this repo.

1. **Vault.** Create a vault (say `Agents`). Copy in only the logins chores need. Each item needs its website URL (matching uses the item's URL field) and a direct username/password; "sign in with" links to another item aren't followed [docs].
2. **Service account.** Create one with `read_items` on that vault only, without vault creation [docs](https://www.1password.dev/service-accounts/get-started). Save the token in your own vault.
3. **Connect it to Kernel from the laptop**, never through the agent: dashboard, Integrations, Connect 1Password [docs]. The MCP can also create providers, but then the token passes through the model [src].
4. **Per site**, create a Managed Auth connection on the existing profile with `credential: {provider, auto: true}` or an explicit `Vault/Item` path, health checks on [docs]. The agent can do this itself: `manage_auth_connections` takes `credential_provider`, `credential_path`, `credential_auto` [src](https://github.com/kernel/kernel-mcp-server).
5. **Agent skill.** Before a logged-in task, check the connection. On `NEEDS_AUTH` (email or SMS code, captcha), hand off the hosted login URL as today.

If the server is compromised: revoke the token, delete **all** Kernel API keys (a key can mint more keys [src]), then rotate the passwords in that vault and sign out other sessions on those sites.

---

## Options compared

| Option | Unattended | Roots unreachable | Model sees password | Where the secret lives | Verdict |
|---|---|---|---|---|---|
| **Service account, token held by Kernel** | Yes | Yes, by vault scoping | No (normal operation) | Token at Kernel, encrypted per org [docs] | **Recommended** |
| Service account, `op` or SDK on the server | Yes | Yes, by vault scoping | Yes, unless you build a separate fill tool | Token on the server (agenix) | Fallback, and the right fit for a self-hosted browser |
| Agentic Autofill ("1Password for Agents") in a Kernel browser | Within a 30-day grant per login | Yes if roots move out of your Private vault; otherwise approval-gated only | No (strongest isolation) | OAuth connection at Kernel; nothing on the server | Workable as an exception; [in depth](#agentic-autofill-in-depth) |
| 1Password Connect | Yes | Yes | Same as `op` | Credentials file and vault cache on the server | Rejected: a service to run, for rate limits you won't hit |
| Browser extension signed in inside the automated browser | No | No | No | Full account keys inside the browser VM | Rejected |
| Kernel's own vault (no 1Password at fill time) | Yes | Yes | No (normal operation) | Copy of the values at Kernel | Works, but 1Password stops being the source of truth |

### Service account facts (applies to both service-account rows)

- **Scope.** Chosen vaults only, with `read_items`, `write_items`, `share_items` per vault. Never the Personal, Private, Employee or default Shared vault. Access is immutable: to change it, create a new account [docs]. Up to 100 accounts, so one vault plus one account per agent is cheap.
- **Token.** Shown once. It contains the keys to its vaults, so whoever holds it can decrypt everything in them [docs](https://www.1password.dev/service-accounts/security). Optional expiry at creation.
- **Rate limits** (Individual and Families): 1,000 reads and 100 writes per hour per token, 1,000 requests per day per account [docs](https://www.1password.dev/service-accounts/rate-limits). A few logins a day is nowhere near.
- **Plan.** Available on Individual and Families [docs]. Extra vaults on Individual [inferred].
- **Revocation.** Revoke or rotate the token, or delete the account, on 1password.com under Developer, Service accounts. Works from a phone browser [docs](https://www.1password.dev/service-accounts/manage-service-accounts).

### Audit and alerting

- 1Password's alertable feeds (Events API, audit log) are **Business only** [docs](https://www.1password.dev/events-api).
- The service-account page documents a "View Item Usage Report" (items accessed, last access, action) [docs], but the [reports page](https://support.1password.com/reports/) says most reports are Business only. Whether an individual or family account gets it: **[unverified]**. Two-minute check in the free trial.
- `op service-account ratelimit <name>` shows request counts per hour and day [docs]. A coarse tripwire, runnable from the laptop.
- Kernel: each connection has an event timeline (logins, re-auths, health checks) and the dashboard lists every auth session [docs]. API audit-log search needs the $200 plan [docs](https://www.kernel.sh/docs/info/audit-logs).
- Nothing here pushes an alert [inferred]. The sites' own new-login emails are the realistic signal.

### Token on the server (fallback)

- `OP_SERVICE_ACCOUNT_TOKEN` in the agent's environment; `op read "op://Agents/<item>/password"` and `...?attribute=otp` for a TOTP code [docs].
- 1Password's own tutorial for this pattern warns it "is not our recommended integration approach" because the model gets raw credentials [docs](https://www.1password.dev/sdks/ai-agent).
- A wrapper that fills outside the model's context is only a convention: the agent runs as the same user and can call `op` itself [inferred].
- With Kernel, `execute_playwright_code` takes model-written code, so the password would pass through the model. Avoiding that needs a local script speaking CDP [inferred].
- Use it if you move to the self-hosted browser, where Playwright MCP's `--secrets` file or agent-browser's auth vault can take values from `op` [src, prior research].

### Why the others fail

- **Connect.** Two containers plus a credentials file on the server, same vault scoping, no rate limits [docs](https://www.1password.dev/connect). It adds an always-on service holding decrypted vault data to solve a limit you won't reach.
- **Extension in the automated browser.** It needs a real account sign-in; service-account tokens authenticate the CLI and SDKs only [docs] [inferred for the extension]. Your account exposes every vault. A second family member fails unattended, since each browser start needs the account password.
- **Credential Broker** (tokenless, OIDC): Business only, GitHub Actions and custom OIDC [docs](https://www.1password.dev/brokered-access).
- **Environments MCP server and the Claude Code plugin**: need the desktop app for approval prompts, and handle env vars, not website logins [docs].

---

## Agentic Autofill in depth

**Short answer:** usable today only through Kernel. The UX is good at a desk and probably missing on the phone. As a threat-model exception it can be made narrow by moving roots out of your Private vault.

How it works: you approve a login in the 1Password app; the 1Password extension inside the browser fetches that one login from an attested enclave, fills it and submits [docs](https://www.1password.dev/agentic-autofill/partners/security). The agent only gets a status back.

### Which providers support it

| Provider | Agentic Autofill | What a solo user needs | Fits a Claude Code agent? |
|---|---|---|---|
| **Kernel** | Yes, "generally available" per Kernel. Kernel runs the OAuth client, loads the extension and creates the request [docs](https://www.kernel.sh/docs/vaults/1password). In the hosted MCP as `manage_vault_credentials` and `manage_vault_items` `1pw_*` operations [src] | An Individual or Families account on 1password.com (US). Any Kernel plan | **Yes, the only one** |
| Browserbase | Yes, as a recipe [docs](https://docs.browserbase.com/integrations/1password/agentic-autofill) | Your own OAuth client, registered in a 1Password **Business** account that 1Password must enable, plus an HTTPS callback backend | No |
| Browser Use Cloud | Yes, two ways [docs](https://docs.browser-use.com/cloud/guides/1password) | Dashboard runs use *their* agent and model, not Claude. The CDP route needs your own OAuth client (Business, enabled by 1Password) | No |
| Anchor, Hyperbrowser, Notte | Service account only [docs] | | Service-account path only |
| Steel, Browserless, Firecrawl, Skyvern, Stagehand | No 1Password integration in their doc indexes [docs] | | |
| Self-hosted (agent-browser, Playwright) | Possible: load the extension, call it over CDP [docs] | Own OAuth client, so Business + enablement | No |
| 1Password for Claude | Yes, consumer feature [docs](https://support.1password.com/1password-claude/) | Mac, Claude desktop app, Claude in Chrome | Not for server agents: it drives your Mac's Chrome, and rc sessions can't use Claude in Chrome (prior research) |

Why Kernel is alone: a partner needs an OAuth client registered in a 1Password Business account [docs](https://www.1password.dev/agentic-autofill/partners/production). Kernel's "Kernel-managed OAuth client" is the only one a consumer can borrow [docs].

### The flow, via Kernel's MCP

Once, then at most every ~90 days:
1. The agent calls `manage_vault_credentials connect_account` and gets a 1password.com consent URL. You sign in and approve [src]. A connection lasts about 90 days at most [docs](https://www.1password.dev/agentic-autofill/partners/disconnect).

Per site, only when a login is needed and no grant is live:
2. The agent creates a credential item (1–5 websites, a goal, a reason per site) and invokes `1pw_create_access_request`. It gets a `onepassword://` approval link and posts it in chat [src].
3. You open the link on a computer with the 1Password desktop app, unlock, pick the login, approve. The prompt closes after 2 minutes [docs].
4. The agent polls `1pw_access_request_status` (every 2 s, stops at 3 min) [src]. It opens a browser with the vault and the `personal` profile attached, goes to the login form and invokes `1pw_fill`. The extension fills username, password and the current TOTP code, then submits; multi-page logins fill once per page [docs].
5. The session lands in the profile as today. For 30 days the agent can fill that login again whenever it's logged out, without you [docs].

After 30 days the grant ends silently: the item still says `ready` and the next fill fails. The agent then creates a new item and asks again [docs].

### UX verdict

- **At the desk: good.** One click plus unlock per site, at most monthly, up to 5 sites per request. Better than today's hand-off: no typing passwords or codes into a hosted page.
- **On the phone: probably not yet.** Partner docs say approving from a link in the mobile apps is "in development", and so is approval on 1password.com [docs](https://www.1password.dev/agentic-autofill/partners/approval). The consumer page lists iOS and Android 8.12.42, but that covers partner apps that embed approval [docs]. **Test by tapping a link on the iPhone.** If it fails, a chore that needs a fresh grant waits until you're at a computer.
- **Desktop app:** stable 1Password for Mac and Linux 8.12.38 (2026-10-05) added agent approval [docs: release notes]. Partner docs still say Nightly. Conflicting.
- **Fills are unattended within a grant**, so scheduled chores work [docs]. Email and SMS codes still need you.
- **No auto re-login by Kernel.** Managed Auth's health checks and re-auth take service accounts only [docs]. The agent must notice it's logged out and fill.
- **Approval prompts say "Kernel"**, with the agent-written goal and reason [docs].

### The exception you'd be carving out

What a compromised server or a misled agent can do with the Kernel key:
- **Request any Login in your Personal/Private vault**, with goal and reason text of its choosing. It gets nothing until you approve, and you choose the item [docs].
- **Use every login you approved in the last 30 days**, without you, in a browser it controls ("standing access") [docs](https://www.1password.dev/agentic-autofill/partners/security). Assume it can read those passwords: the values sit in the page until submit, and a script it planted earlier can catch them [inferred; both vendors say this is not secret isolation].
- **Not** read TOTP seeds: only current codes are filled [docs]. **Not** list your items or approve its own requests [docs].

**Make it narrow: move roots out of the Private vault.** Agentic Autofill only grants from Personal (Individual) or Private (Families); logins in other vaults aren't offered [docs]. Put Google, GitHub, Apple, claude.ai and anything that can reset them (mail, carrier, registrar) in a separate vault, and they can't be requested at all [docs + inferred; verify in the trial]. Your own browser still autofills from every vault. Recheck when 1Password ships shared-vault support, which is planned [docs](https://www.1password.dev/agentic-autofill/partners/faq).

The exception would then read: *"The server may ask for any non-root login, and may use one for 30 days after I approve it."*

| Requirement | Agentic Autofill via Kernel |
|---|---|
| Revoke in one step from another machine | **Partly.** Not possible from inside 1Password [docs]. Deleting the Kernel API keys in the dashboard cuts an attacker off; `1pw_disconnect` then ends the connection [docs]. Whether the Kernel dashboard has a disconnect button: [unverified]. |
| Detect misuse | **Better than a service account.** Every *new* login needs your approval, so silent new access is impossible. Reuse within 30 days is silent. Kernel keeps immutable item events [docs]; whether fills appear there: [unverified]. |
| Model never sees the password | **Strongest of all options.** The extension fills, and Kernel locks out CDP during the fill [docs]. Still not a boundary against a hostile agent (above). |
| Unattended boot | Yes. Nothing 1Password-related on the server. |
| Nothing stored at Kernel | Kernel keeps encrypted connection material and grant references, no passwords or seeds [docs]. |

Other limits: no passkeys and no "sign in with Google" items [docs]; US 1password.com accounts only [docs]; 1Password labels the API "partner preview, can change" while Kernel calls it GA [docs]; whether `1pw_fill` works in headless browsers: [unverified] (headful costs 8× but still cents).

### Recommendation

Trial it at the desk, then decide on the iPhone result:
1. Start the 1Password trial, move roots to a separate vault, connect Kernel.
2. Approve one low-value site and confirm a root login isn't offered.
3. Tap an approval link on the iPhone. Check a headless fill and Kernel's item events.

If iPhone approval works, I'd take this over the service account: no secrets at Kernel, and every new grant is visible to you. If it doesn't and you mostly start chores from the phone, use the service-account setup and revisit.

---

## Pricing

### Kernel Managed Auth with a 1Password service account

No per-connection fee and no charge for the 1Password provider; you pay the plan plus browser seconds for logins and health checks [pricing](https://www.kernel.sh/pricing).

| | Free (Developer) | Hobbyist |
|---|---|---|
| Monthly | $0, with $5 usage credit | $30, with $10 usage credit |
| Managed-auth connections | 3 | Unlimited |
| Health-check interval | 6 h minimum | 1 h minimum (the default) |

Sources: [pricing](https://www.kernel.sh/docs/info/pricing), [docs](https://www.kernel.sh/docs/browsers/concurrency-and-limits), API reference.

- **Browser time:** headful $0.48/h, headless $0.06/h, billed per second [pricing]. A check or login takes 5–30 s [docs]. Which kind health checks use: [unverified].
- **Estimates** [inferred], at 15 s per check, worst case headful:
  - Free, 3 sites, every 6 h: about 1.5 browser-hours a month, ≤ $0.72, inside the credit. **$0.**
  - Hobbyist, 10 sites, every hour: about 30 h, ≤ $14, so **~$34/mo** after the credit. Set the interval to 6 h: about 5 h, ≤ $2.40. **$30 flat.**
  - Kernel's own claim is that 100 connections usually cost under $5/mo [pricing], so real checks are cheaper than my worst case.
- **1Password side:** service accounts are included [docs]. Rate limits don't bite: Kernel caches the item list for 5 minutes by default [src].

### Kernel with Agentic Autofill

- Uses no managed-auth connections, so the 3-connection cap doesn't apply. Needs one Kernel vault (Free allows 3) [pricing]. Cost is a few browser-seconds per fill: **effectively $0 on Free**.
- Free allows 1 custom extension. Kernel loads the 1Password extension itself, so it probably doesn't count [unverified].
- 1Password for Agents is included in Individual and Families at no extra cost [unverified: press reports; the support page only lists the account requirement].

### 1Password

Individual $3.99/mo, Families $5.99/mo, billed yearly; first-year promo $2.99 / $4.49 [pricing](https://1password.com/pricing/password-manager).

---

## Second factors

| Factor | Unattended? | Detail |
|---|---|---|
| TOTP seed in the 1Password item | Yes | Kernel generates codes from the item's seed at login and re-login [docs]. On the server, `op read ...?attribute=otp` [docs]. With Agentic Autofill the seed never leaves 1Password; only the current code is filled [docs]. |
| Passkey stored in 1Password | No | Service accounts and SDKs can't read passkeys; Agentic Autofill doesn't fill them; Managed Auth fails with `unsupported_auth_method` [docs]. |
| Email code | No | Needs a mailbox, and the mailbox is a root. The connection goes to `NEEDS_AUTH` and you enter the code [docs]. |
| SMS code, push approval | No | Same [docs]. |

- **Passkey-first conflicts with agent use.** Sites the agent logs into need password plus TOTP kept enabled. Alternative: Kernel can register and hold a separate agent-only passkey per site, signing on its servers (vaults, preview) [docs](https://www.kernel.sh/docs/vaults/passkeys).
- **Both factors in one vault** means TOTP no longer protects against whoever holds the token. It still protects against a reused or phished password. Fine for low-value logins.
- **Two rules** [inferred]: no root's seed ever enters the agent vault, and no account that can reset a root goes in it (mail provider, domain registrar, mobile carrier).

## How the credential reaches the browser

| Option | Path |
|---|---|
| Token held by Kernel | Kernel's backend reads the item with the token and types it into the site in a login session it runs itself. The resulting session is saved to the profile, and the agent's browser loads that profile. The password never crosses the server [docs]. |
| Token on the server | `op` decrypts on the server, then the value travels over the network into the Kernel browser, and through the model if the model writes the fill code [inferred]. |
| Agentic Autofill | The 1Password extension inside the Kernel browser receives the one approved login from 1Password's enclave and fills it [docs]. |
| Kernel's own vault | You type values once into a Kernel-hosted form; `fill` injects them from Kernel's backend [docs]. |

### Can the model be kept away from the password?

- **For transcripts and logs: yes.** In the recommended setup and in Agentic Autofill the value never enters model context.
- **As a boundary against a hostile agent: no, in any option.** Kernel says so itself: after a fill, page scripts or an agent with browser access can read the values [docs](https://www.kernel.sh/docs/vaults/overview). An agent holding the Kernel key can also point a login at a page of its choosing (Risks).
- The threat model already writes off the agent vault's contents, so this is acceptable.

---

## NixOS fit

**Recommended setup: no packages, no modules.** The only server secret stays `KERNEL_API_KEY`, which `claude-rc.nix` loads into the unit from an env file. The target is for that file to be an agenix secret (encrypted to the server host key), outside any synced tree:

- **Delivery.** `jl.claude.rc.dirs.<name>` gains a data option for extra env files, which the host sets for the one agent that needs it. No `enable` option.
- **Secret.** Env-file form, recipients `withServer`, declared in `hosts/server.nix`, owned by the agent user.

**Fallback (token on the server), described, not built.** Same delivery and secret shape for `OP_SERVICE_ACCOUNT_TOKEN`, plus:

- **Package.** `pkgs._1password-cli` (2.41.1, unfree; `allowUnfree` is already set centrally) in `home.packages` of `flake.modules.homeManager.agents` [src]. Python SDK is `python3Packages.onepassword-sdk` 0.4.0 [src].
- **Not `programs._1password`.** That module wraps `op` setgid for desktop-app integration [src]; a service-account token doesn't need it [inferred].
- **opnix** ([repo](https://github.com/brizzbuzz/opnix), v0.11.0, 2026-08-18, flake input, not in nixpkgs): `services.onepassword-secrets` fetches `op://` references to files at boot using a token file [docs]. Wrong shape here: it would leave each website password in a file on the server. It fits the agenix question below.
- **Public repo.** `op://Vault/Item` references are metadata that would be published. Keep names generic.

## Could this replace agenix for server secrets?

**Not worth it now. Security is equal; availability and complexity get slightly worse.**

- The service-account token is itself a secret that must reach the server, so agenix (or a manual step) stays for that one secret [inferred].
- Blast radius is the same: hostile code on the server reads the secrets either way.
- Better: rotation is an edit in the app plus a service restart, revocation is one click, and no ciphertext sits in a public repo.
- Worse: boot depends on 1password.com and the daily request quota, one more flake input with a single maintainer, and secrets no longer roll back with the system.
- If you do it later, use a separate vault and service account from the agent one, so revoking either leaves the other working.

---

## Risks

- **The Kernel API key is worth the whole agent vault.** A holder can attach any item in the vault to a login for a domain it picks, and credential entry is unrestricted when `allowed_domains` is empty [docs] [src]. I did not find a check that the item's URL matches [unverified]. TOTP seeds are not returned, only used [inferred].
- **Kernel becomes the single point** for these sites: sessions, plus the token. Keep the vault low-value.
- **Wrong item.** With `auto: true` the first URL match wins [docs]. One item per domain, or use explicit paths.
- **Lockouts.** Automated re-logins can trip a site's risk checks. Kernel doesn't retry a conclusive rejection [docs].
- **Churn.** Kernel vaults are "preview" and 1Password's autofill docs are "partner preview". Managed Auth with a service account is the older, plainer path.
- **Optional hardening.** A scoped Kernel key (browsers plus one profile) can't manage keys and appears to get 403 on Managed Auth [docs] [inferred]. The server would then hold only "use this logged-in profile". Whether the hosted MCP works with it: [unverified].

## Open questions

1. Does an individual or family account show the service-account usage report? Decides whether any item-level read log exists.
2. Does Kernel validate an explicitly pathed item against the connection's domain?
3. Does the 1Password provider work on Kernel's free plan? The pricing page doesn't gate it.
4. Do scoped Kernel keys work through the hosted MCP?
5. Agentic Autofill: does tapping a `onepassword://` approval link on the iPhone work today?
6. Agentic Autofill: does `1pw_fill` work in a headless Kernel browser, and do fills show up in Kernel's item events?
7. Agentic Autofill: when do shared vaults and longer grants ship? Shared vaults would also change what the vault-move mitigation covers.

# Browser use for the chore agent — research

Date: 2026-09-25. Prices and features move monthly; every claim below is as of this date.

Evidence tags: **[docs]** vendor docs, **[src]** read in the source repo, **[pricing]** vendor pricing page, **[inferred]** my reasoning, **[unverified]** a claim I found but could not confirm.

## Verdict

**Use Kernel (kernel.sh) through its hosted MCP server, authenticated with an API key.** It is the only option I found where the whole "agent sees it needs a login → gives you a URL → you log in on your phone, 2FA included → the login persists" loop works as MCP tools returning plain text. That matters because a `claude rc` session probably can't render MCP Apps or forward URL elicitations to the phone. The pieces:

- **Managed Auth** returns a `hosted_url` and a `live_view_url` to the model [src].
- A `wait` action blocks until the login finishes [src].
- **Profiles** persist the whole browser user-data directory, encrypted [docs].
- **Health checks** re-authenticate automatically when a site's login lapses [docs].

At your volume it costs about **$0–2 a month** on the free tier (3 managed-auth sites), or **$30 a month** for unlimited sites.

Browserbase Contexts, the thing you liked, don't carry over well to MCP:

- Its MCP repo was **archived on 2026-07-20** [docs].
- The hosted MCP documents no `contextId` parameter [docs].
- The `start` tool never returns a Live View URL [src].

**Fallback:** self-host on the server. `agent-browser` (in nixpkgs, 0.38.1) runs headed Chrome under Xvfb with a persistent profile. Its dashboard has an interactive live viewport that you can reverse-proxy over Tailscale. That's free and private, and it runs from your home's residential IP. For sites that block everything else, drive the Mac's real Chrome (see Hybrid).

---

## Recommended setup

### Primary: Kernel hosted MCP

`.mcp.json` in the vault subdirectory:

```json
{
  "mcpServers": {
    "kernel": {
      "type": "http",
      "url": "https://mcp.onkernel.com/mcp",
      "headers": { "Authorization": "Bearer ${KERNEL_API_KEY}" }
    }
  }
}
```

- **Secret:** `KERNEL_API_KEY`, a project-scoped Kernel API key, set as an env var on the chore-agent service through the deposit mechanism.
  - Use an API key, not OAuth. OAuth needs an interactive `/mcp` login, which a headless `rc` session makes awkward.
  - The server accepts opaque bearer tokens as API keys [src: `src/app/[transport]/route.ts`, `handleAuthenticatedRequest`]. The docs only show OAuth, so this is source-verified only.
- **Alternative with no Anthropic-side HTTP:** `npx -y mcp-remote https://mcp.onkernel.com/mcp --header "Authorization: Bearer ${KERNEL_API_KEY}"` [docs mention mcp-remote; the header form is inferred].
- **Tool surface is large** (about 25 tools; `manage_*` tools take an `action` parameter) [src]. Expect tool search to defer most of them.

### Fallback A: self-hosted agent-browser on the server

- **Package:** `pkgs.agent-browser` (0.38.1).
- **MCP:** `agent-browser mcp` gives a stdio MCP [docs].
- **Environment:**
  - `AGENT_BROWSER_PROFILE=/var/lib/chore/browser-profile`: persistent Chrome profile [docs]
  - `AGENT_BROWSER_HEADED=1`: starts Xvfb itself on a display-less Linux box [docs]
  - `AGENT_BROWSER_DASHBOARD_ALLOWED_ORIGINS=https://server.<tailnet>.ts.net` [docs]
- **Live view:** `agent-browser dashboard start` serves port 4848. Put `tailscale serve` HTTPS in front of it. Access from external origins uses a tokenized URL, then a host-bound cookie [docs].
- **Phone input:** the stream accepts mouse, keyboard and touch input [docs].
- No secret needed.

### Fallback B: hybrid, the Mac's real Chrome

See the Hybrid section.

---

## Comparison table

Personal volume here means 50 sessions a month at about 5 minutes each, roughly 4.2 browser-hours.

| Option | Persistent context | Live-view login hand-off | Phone-friendly | Stealth / captcha / proxy | MCP official? transport | Self-host | ~$/mo at personal volume | nixpkgs / npx |
|---|---|---|---|---|---|---|---|---|
| **Kernel** | Yes: full user-data dir, encrypted; Managed Auth per domain | **Yes**: `hosted_url` + `live_view_url` returned to the model; `wait` + `submit` (MFA code) | Yes: hosted login page, live view needs no auth [docs] | Stealth: ISP proxy + captcha solver [docs] | Official, remote HTTP (OAuth or API key) | Browser image OSS (`kernel-images`); platform no | **~$0.25 headless / ~$2 headful**, inside $5 free credits; $30 Hobbyist for >3 auth sites | `mcp-remote` via npx; no nixpkgs |
| **Steel.dev** | Yes: Profiles (cookies, storage, fingerprint) [docs] | Yes, but via MCP Apps / URL elicitation. Fallback: `viewer_url` in `session_create` text [src] | Yes (debug player needs no Steel login) [src] | Proxies + captcha need $10 paid balance [docs] | Official, stdio (`npx -y github:steel-dev/steel-mcp-server`); hosted "not yet live" | Yes, Apache-2.0 docker; **no profiles, captcha or proxies self-hosted** [src] | ~$0.42 from $30 one-time credits; **15-min session cap on Launch** [pricing] | npx from GitHub only |
| **Browserbase** | Yes: Contexts, indefinite retention [docs] | Live View exists [docs], but **MCP doesn't return it**; dashboard URL needs a BB login [src] | Mobile keyboard "not officially supported" [docs] | Basic stealth on Dev; Advanced on Scale only [pricing] | Hosted remote; stdio repo **archived 2026-07-20**; hosted has no `contextId` param [docs] | No | $20 Developer (free = 1 hr) [pricing] | `@browserbasehq/mcp` (archived) |
| **Anchor Browser** | Yes: profiles / "Authenticated browsers" (Starter) [docs] | Live view: [unverified] detail | [unverified] | Stealth + captcha; full stealth only on Growth ($2k) [pricing] | Official hosted `api.anchorbrowser.io/mcp`, header key [docs] | No | ~$0.71 of $5 free credits; auth features on $50 Starter [pricing] | Remote only |
| **Hyperbrowser** | Yes: profiles, `persistChanges` [docs] | Dashboard live view only [unverified] | ? | Advanced stealth on $100 Scale [unverified] | Official stdio `npx hyperbrowser-mcp`; profile CRUD + agent tools, no live URL [docs] | No | $30 Startup [unverified] | npx |
| **Browserless** | Yes: persisted sessions / profiles [docs] | `Browserless.liveURL` CDP command; MCP doesn't expose it to the model [docs] | Quality knob "useful for mobile" [docs] | Stealth; captcha 10 units; residential 6 units/MB [pricing] | Official hosted `mcp.browserless.io/mcp` + bearer [docs] | OSS is SSPL/non-commercial; liveURL looks Enterprise [inferred] | Free tier has a 2-min session cap, so not viable; $25/mo Prototyping (annual) [pricing] | Remote |
| **Browser Use Cloud** | Profiles; **cookie-only** sync from local Chrome [docs] | `get_session` returns a live URL [docs] | ? | Stealth browsers, country proxies [docs] | Official hosted `api.browser-use.com/v3/mcp`; **runs their agent + LLM**, not Claude driving [docs] | Library OSS | $0.02/h + 20% of token rates [docs] | uvx `browser-use` |
| **Firecrawl Browser** | Named profiles, `saveChanges` [docs] | `interactiveLiveViewUrl` [docs] | iframe [docs] | ? | MCP "tools" mentioned [unverified] | No | 2 credits/min [docs]; plan cost [unverified] | npx firecrawl-mcp |
| **Bright Data Browser API** | No persistent login story found | No | – | Best-in-class unblocker | Official `@brightdata/mcp` | No | Platform ~$500/mo tiers [unverified] | npx |
| **Cloudflare Browser Run** | Named reusable sessions, keep_alive ≤10 min [docs] | Yes: Live View + HITL handoff (Apr/Jul 2026) [docs] | ? | **"Always identified as bot traffic"** [docs], so disqualified | `@cloudflare/playwright-mcp` (Workers-deployed) | No | Free tier + usage | npm |
| **Playwright MCP self-host** | `--user-data-dir` / `--storage-state` [src] | **None built in.** Needs Xvfb + noVNC | Via noVNC | None (Chromium flags `webdriver`) [inferred] | Official stdio/HTTP | Yes | $0 | `pkgs.playwright-mcp` 0.0.80 |
| **agent-browser self-host** | `--profile`, `--session --restore`, auth vault [docs] | **Dashboard with interactive viewport** [docs] | Touch input supported [docs] | None beyond headed + residential IP | stdio `agent-browser mcp` | Yes | $0 | `pkgs.agent-browser` 0.38.1 |
| **chrome-devtools-mcp** | `--userDataDir` | None | – | None | Official (Google), stdio | Yes | $0 | npx only |
| **Hybrid: Mac Chrome** | Your real profile | Not needed: already logged in | You log in on the Mac | Real browser, real IP | Playwright MCP `--extension` over HTTP | Yes | $0 | `pkgs.playwright-mcp` on darwin |

---

## Per-option notes

### Kernel ([kernel.sh](https://www.kernel.sh))

**Profiles**
- Capture the whole user-data dir: cookies, site data, tabs, preferences. Encrypted. Kept until deleted [docs](https://www.kernel.sh/docs/browsers/profiles).
- **Gotcha:** with `save_changes: true`, changes persist **only when the browser is deleted**, not when it's closed [docs]. The agent must delete its browser at the end of a chore.

**Managed Auth** [docs](https://www.kernel.sh/docs/auth/managed-auth)
- A connection is one domain attached to a profile; one profile can hold many domains.
- The hosted page shows the real site's login, including 2FA.
- Timing: the flow expires after 20 minutes, and times out after 10 minutes without user input [docs](https://www.kernel.sh/docs/auth/hosted-ui).
- TOTP can be automated if you store the secret.
- SMS, email and push approvals still need you.
- Periodic health checks re-login automatically when they can; "recovery isn't guaranteed" [docs].
- Included on every plan. The free plan caps it at 3 auth connections; Hobbyist ($30) is unlimited [pricing](https://www.kernel.sh/pricing).

**MCP** ([repo](https://github.com/kernel/kernel-mcp-server), [registry](https://registry.modelcontextprotocol.io/v0/servers?search=onkernel) `com.onkernel/kernel-mcp-server`, last commit 2026-09-24)
- `manage_auth_connections` actions: `create/list/get/login/submit/wait/...`.
- `login` returns raw JSON including `hosted_url` and `live_view_url` [src: auth-connections.test.ts].
- `open_auth_login` is the MCP-Apps version and deliberately hides the URL from the model [src]. **Don't rely on it under rc; use `manage_auth_connections login`.**
- Browsers are driven through `manage_browsers`, `execute_playwright_code` and `computer_action` [src].

**Live view** [docs](https://www.kernel.sh/docs/browsers/live-view)
- Interactive by default; `readOnly` is optional.
- No auth is mentioned for opening the URL.
- Dies when the browser is deleted.

**Pricing** [pricing](https://www.kernel.sh/docs/info/pricing)
- Headless $0.06/h, headful $0.48/h.
- You pay only while active: a browser goes to standby 5 seconds after the last CDP or live-view activity.
- Default timeout is 60 seconds in standby; the maximum is 72 hours [docs](https://www.kernel.sh/docs/browsers/termination).
- The pricing page says proxies are "unlimited for Hobbyist+", but the docs pricing page says "configurable proxies require Start-Up" ($200). **Contradiction, unresolved.** `stealth: true` gives a default ISP proxy with a static exit IP for the session [docs](https://www.kernel.sh/docs/browsers/bot-detection/stealth).

**Self-host:** [kernel-images](https://github.com/kernel/kernel-images) is Apache-2.0. It's headful Chromium in docker with WebRTC or noVNC live view on port 443 and CDP on 9222 [docs]. It's a decent self-hosted building block too, but has no profile management.

### Steel.dev

**MCP** ([repo](https://github.com/steel-dev/steel-mcp-server), v3.0.0, last commit 2026-09-09) [src]
- This is the most purpose-built for hand-off.
- It auto-detects `login_wall` (a visible password field) and `captcha` (vendor markers).
- It pauses the tool call with `steel_session_handoff` and resumes after you hand control back.
- **But** the pause only works through MCP Apps (inline viewer) or URL elicitation. Otherwise it throws `client_capability_missing` and tells the agent to give you the `viewer_url`.
- `session_create` always puts "Watch or take control in the live browser: <url>" in its text [src], so the manual path works.
- Profiles and managed credentials (including TOTP) are exposed through `steel_session_options`; secret values never enter model context [docs].

**Pricing** [pricing](https://docs.steel.dev/overview/pricinglimits)
- Launch: $0 + $0.10/h, $30 one-time credits, **15-minute max session**, 7-day retention.
- Scale: $250/mo, 1-hour sessions.
- 15 minutes is tight for a login with a slow SMS plus the chore itself.

**Self-host:** `docker run -p 3000:3000 -p 9223:9223 ghcr.io/steel-dev/steel-browser`, with a UI at `/ui` [docs](https://github.com/steel-dev/steel-browser). The MCP in `STEEL_LOCAL=true` mode runs one session, "no managed proxies, browser profiles, managed credentials, or CAPTCHA solving" [src]. Self-hosted Steel therefore loses the persistence you want.

**Registry:** not in the official MCP registry.

### Browserbase

**Contexts:** persist cookies, localStorage, IndexedDB and more "indefinitely". Wait a few seconds after closing before reuse. Don't run two sessions on one context [docs](https://docs.browserbase.com/features/contexts).

**Live View** [docs](https://docs.browserbase.com/features/session-live-view)
- `debuggerFullscreenUrl`, interactive.
- Mobile works via viewport size, but "Mobile keyboards aren't officially supported".
- **Typing a password or OTP on your phone is exactly the weak spot.**

**MCP**
- `mcp-server-browserbase` was archived on 2026-07-20 [docs](https://github.com/browserbase/mcp-server-browserbase).
- The hosted `https://mcp.browserbase.com/mcp?browserbaseApiKey=...` lists `keepAlive`, `proxies`, `verified` and `modelName`, and **no `contextId`** [docs](https://docs.browserbase.com/integrations/mcp/configuration).
- The tools (`act/observe/extract`) are Stagehand natural-language calls backed by a separate LLM (Gemini by default), so there's a second model and a second bill.
- `start` returns only `sessionId` [src].

**New direction:** the `browse` CLI (`npm i -g browse`) plus a `cookie-sync` skill that copies cookies from local Chrome over CDP into a Context [docs](https://github.com/browserbase/skills). It's CLI and skill based, not MCP.

**Pricing** [pricing](https://www.browserbase.com/pricing)
- Free: 1 hr/mo.
- Developer: $20/mo for 100 hrs, 1 GB proxy, "Basic" stealth + captcha.
- Advanced stealth / Verified: Scale (custom) only.

### Others (brief)

**Anchor**
- Hosted MCP at `https://api.anchorbrowser.io/mcp`, header `anchor-api-key` [docs](https://docs.anchorbrowser.io/advanced/mcp).
- Pricing: $0.05/h + $0.01 per browser + $8/GB proxy; free plan has $5/mo credit; "Authenticated browsers" on Starter at $50 [pricing](https://docs.anchorbrowser.io/pricing).
- I didn't verify how live-view hand-off works through its MCP.

**Hyperbrowser**
- `npx hyperbrowser-mcp <key>`: scrape/crawl, `browser_use_agent`, `claude_computer_use_agent`, and profile create/list/delete [docs](https://github.com/hyperbrowserai/mcp).
- The profile tools help, but there's no live URL for login. You'd log in through the SDK or dashboard.

**Browserless**
- Hosted MCP with a `profiles` tool and liveURL marketing [docs](https://docs.browserless.io/mcp/browserless-mcp-server).
- `Browserless.liveURL` is a one-time link with `liveComplete` events: good primitives [docs](https://docs.browserless.io/baas/interactive-browser-sessions/hybrid-automation).
- The MCP doesn't hand the URL to the model, as far as I found.
- The free tier's 2-minute session cap kills it.

**Browser Use Cloud**
- The MCP runs *their* agent on their models ($0.02/h browser + 20% of token rates). Claude isn't driving, which is wrong for a Claude chore agent [docs](https://docs.cloud.browser-use.com/usage/mcp-server).
- Profile sync (`curl -fsSL https://browser-use.com/profile.sh | sh`) moves **cookies only**, not localStorage or IndexedDB, and "does not guarantee that the target site accepts a moved login" [docs](https://docs.browser-use.com/cloud/guides/profile-sync).

**Firecrawl Browser Sandbox**
- Has everything on paper: named profiles with `saveChanges`, an `interactiveLiveViewUrl`, TTL up to 1 hour, 2 credits/min [docs](https://docs.firecrawl.dev/features/browser).
- Whether its MCP exposes the interactive URL: [unverified].

**Cloudflare Browser Run**
- Added Live View and Human-in-the-Loop handoff (`Cloudflare.handoff` CDP) in 2026 [docs](https://developers.cloudflare.com/browser-run/features/human-in-the-loop/).
- But its "requests are always identified as bot traffic" [docs]. Dead on arrival for banks and insurers.

**Bright Data:** strong unblocker, scraping-oriented (`@brightdata/mcp`, in the registry). I found no persistent-login or hand-off story.

### Self-hosted on NixOS

**Playwright MCP** (`pkgs.playwright-mcp` 0.0.80; registry `io.github.microsoft/playwright-mcp`)
- A persistent profile is the default (`~/.cache/ms-playwright/mcp-…`) or `--user-data-dir`.
- `--storage-state` loads a cookie/localStorage JSON into an isolated context.
- `--secrets` takes a dotenv file.
- `--idle-timeout` defaults to 1 hour headless.
- One browser per profile [src README].
- **No live view.** To hand off: run headed under Xvfb (`services.xserver` or a `xvfb-run` wrapper), run `x11vnc` on that display, run `novnc` (`pkgs.novnc` 1.7.0), and put `tailscale serve` in front.
- noVNC on a phone works but is clumsy (no native keyboard focus; pinch-zoom) [inferred]. KasmVNC and Selkies are nicer on phones but aren't in nixpkgs (containers only).

**agent-browser** (Vercel)
- In nixpkgs.
- Profiles, `--session --restore`, a local encrypted auth vault, headed mode that auto-starts Xvfb, and an interactive dashboard stream (mouse, keyboard, touch). Also an `mcp` subcommand [docs](https://agent-browser.dev/dashboard), [docs](https://agent-browser.dev/streaming).
- It can also front Kernel, Browserbase, Browserless or Browser Use as `--provider` [docs].
- It's the best self-hosted fit for the hand-off flow because the viewer is built in.
- Weakness: no stealth. It's plain Chrome over CDP.

**chrome-devtools-mcp** (npx only; registry `io.github.ChromeDevTools/chrome-devtools-mcp` 1.10.1)
- Good for debugging.
- `--userDataDir`, `--browserUrl` / `--wsEndpoint` for remote Chrome [docs](https://github.com/ChromeDevTools/chrome-devtools-mcp).
- `--autoConnect` (Chrome 144+) attaches to your *real* running Chrome, but **Chrome shows an "Allow remote debugging?" dialog on every connection**. The request to persist approval was closed as not planned ([#825](https://github.com/ChromeDevTools/chrome-devtools-mcp/issues/825)). Useless unattended.

**Lightpanda:** headless-only engine, not in nixpkgs, no display. Wrong tool for logged-in consumer sites [inferred].

**Aether agent-browser** (registry `io.github.AetherAI3/agent-browser`, 8 stars): headed Chrome with a noVNC takeover, and `browser_navigate` returns the live-view URL [docs](https://github.com/AetherAI3/agent-browser). Exactly the right shape, but too immature to depend on.

### Bot protection in practice [inferred unless tagged]

**Your home server's IP is residential ISP space.** That's a real advantage over datacenter headless setups, and it's the *same* IP every time, which banks like. The weak point is the fingerprint:

- Playwright/CDP Chromium sets `navigator.webdriver`.
- `Runtime.enable` leaks are detectable.
- Headless has tells.

Headed real Chrome (not Chromium-for-Testing) under Xvfb with a long-lived profile passes most consumer sites. Akamai and Kasada on banks will still challenge sometimes. Hosted "stealth" mostly means residential/ISP proxies plus captcha solvers; captcha solving on a bank login is itself a risk signal.

The biggest practical risk with hosted providers: the **exit IP and location change between sessions**. Banks then treat each run as a new device and new location and fire 2FA every time. That hurts the persistence story more than detection does.

---

## Hybrid: drive the Mac's real Chrome

**Why it's attractive:** you're already logged in everywhere, on a real fingerprint and a residential IP, with real 2FA device trust. It removes the login problem for sites you use on the laptop.

**Recommended variant: Playwright MCP extension mode, served from the Mac.** It avoids the CDP-port approach's Chrome 136+ rule, which refuses `--remote-debugging-port` on the default profile [docs](https://github.com/ChromeDevTools/chrome-devtools-mcp).

1. Install the "Playwright MCP Bridge" extension in your normal Chrome profile. Copy `PLAYWRIGHT_MCP_EXTENSION_TOKEN` from its UI; the token skips the per-connection approval [docs](https://github.com/microsoft/playwright/tree/main/packages/extension).
2. On the Mac, add a nix-darwin `launchd.user.agents.playwright-mcp` that runs `playwright-mcp --extension --port 8931 --host <mac-tailscale-ip> --allowed-hosts <mac>.<tailnet>.ts.net`, with the token set in its env.
3. On the server, add to `.mcp.json`: `{"type":"http","url":"http://<mac>.<tailnet>.ts.net:8931/mcp"}`.
4. Add a Tailscale ACL so only the server's tag can reach `mac:8931`. The endpoint has **no auth of its own**; anything that can reach it drives your logged-in browser.

**Alternative CDP variant**
- Run a second Chrome with `--remote-debugging-port=9222 --user-data-dir=~/.chrome-agent`, log into sites there once, and expose it with `tailscale serve --tcp 9222`.
- Point `chrome-devtools-mcp --wsEndpoint ws://mac:9222/devtools/browser/<id>` or Playwright `connectOverCDP` at it.
- Gotchas [inferred]:
  - `/json/version` advertises a `ws://127.0.0.1` URL, so `--browserUrl` breaks remotely; use an explicit ws endpoint.
  - The browser ID changes on every restart.
  - It's a separate profile, so you log in once more (on the Mac, easily).

**Downsides (real)**
- **The laptop must be awake**, lid open or on power with `pmset` / `caffeinate`. Chores then happen only when the Mac is on.
- **The agent works in your live profile:** it can read any logged-in site and open tabs while you're using the browser. Tab hijacking and focus fights happen [inferred].
- **Blast radius:** a prompt-injected page can act as you on *every* site. This is the worst case of all the options.
- Playwright MCP's `--allowed-origins` "does not serve as a security boundary" [src].

**When to use it:** as the "can't get past bot protection or device trust anywhere else" escape hatch, not the default.

---

## Login hand-off flow (Kernel)

One-time setup: create one profile (e.g. `personal`). Each site becomes an auth connection bound to that profile.

1. **Detect.** Before a chore on domain X, call `manage_auth_connections list` and find X.
   - If it's missing or not `AUTHENTICATED`, go to step 2.
   - Mid-task, treat any of these as logged out: a redirect to a `/login` / `/signin` path, a visible password field (the same heuristic Steel uses [src]), or a site-specific "account menu" element missing. Then re-check the connection status.
2. **Start.** `create {domain: X, profile_name: "personal"}` if the connection is new, then `login`. That returns `hosted_url` (and `live_view_url`) [src].
3. **Hand off.** The agent posts `hosted_url` in chat. rc push notifications ("Push when Claude decides") ping your phone [docs](https://code.claude.com/docs/en/remote-control).
4. **You log in** on the phone: real site UI, credentials, SMS or app 2FA. You have 10 minutes of idle allowance and 20 minutes total [docs].
   - If a code arrives somewhere awkward, paste it in chat. The agent relays it with `submit {fields: {mfa_code}}` [src].
5. **Wait.** The agent calls `manage_auth_connections wait` (SSE-backed) until `AUTHENTICATED` or failure [src].
6. **Resume.** `manage_browsers create {profile: {name: "personal"}, stealth: true}`. Do the chore with `execute_playwright_code` / `computer_action`. **Delete the browser at the end.**
7. **Later sessions** load the profile already logged in. Kernel health checks re-login on their own when possible; otherwise the loop repeats at step 1.

For an ad-hoc takeover (captcha, "confirm this payment"), the agent sends `live_view_url` from the browser it created.

---

## Risks

**Bot detection and account bans**
- Automated logins to banks can trip fraud systems and lock the account. Worst with captcha solvers and rotating proxy IPs.
- Prefer a stable IP: self-hosted at home, or a pinned ISP proxy.
- Keep bank chores read-mostly, and have the agent hand off before any money-moving action.

**Cookies held by a third party**
- Kernel stores live bank and insurance sessions (encrypted, but they hold the keys).
- A breach there or a leaked API key means session theft with your 2FA already satisfied.
- Mitigations:
  - Use a project-scoped key.
  - Keep financial sites off the hosted profile (use the hybrid or self-host for those).
  - Rotate the key via the deposit mechanism.

**Prompt injection:** any browsing agent with logged-in sessions can be steered by page content. The hybrid (your real profile) is the largest blast radius, and a single-purpose Kernel profile the smallest.

**Cost creep**
- Headful Kernel browsers are 8× the price of headless.
- Browserbase and Steel paid tiers jump to $20–250 a month for session-length limits, not usage.
- At 4 hours a month, every option except the Browserbase and Browserless subscriptions costs under $3.

**Vendor churn:** Browserbase archived its MCP within a year, and Steel's hosted MCP "not yet live". Expect breakage. Pin versions and keep the self-hosted fallback working.

---

## Open questions (couldn't verify)

1. **Does `claude rc` forward MCP elicitations (form or URL) or render MCP Apps on the phone?**
   - The docs say URL elicitation opens the link with the *local* URL handler [docs](https://code.claude.com/docs/en/mcp), which is useless on a headless server.
   - The rc docs only mention forwarding permission prompts, `AskUserQuestion`, and "other dialogs" with a 5-minute expiry.
   - If rc does forward them, Steel's native pause/resume and Kernel's `open_auth_login` become nicer. Test with one elicitation.
2. **Claude in Chrome with rc:** not available. rc-spawned sessions don't get the chrome tools, and `claude remote-control --chrome` errors ([#74671](https://github.com/anthropics/claude-code/issues/74671), open). It would also need Chrome on the server. The "remote devices / built-in browser" linkage in the desktop app seems aimed at cloud sessions linked to a computer; whether an rc session on the server can use the Mac's Claude Browser is unknown.
3. **Kernel:** do proxies work on Free/Hobbyist (the docs contradict each other)? Can a static ISP exit IP be pinned per profile, so banks see one location? Does the hosted Managed Auth page stream the real site or render discovered fields? The docs say "see the login page for the target website".
4. **Kernel MCP API-key auth** is source-verified, not documented. It could change.
5. **Anchor and Hyperbrowser** live-view-via-MCP details and phone keyboard handling.
6. **Firecrawl MCP:** does it expose `interactiveLiveViewUrl` and profiles?
7. **Playwright extension mode:** does it work when the Mac's Chrome is not in the foreground or the screen is locked? It probably needs the user session unlocked [inferred].

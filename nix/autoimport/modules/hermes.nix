# Hermes Agent — self-improving AI assistant, reachable over Telegram.
# https://github.com/NousResearch/hermes-agent
#
# Runs on the server as an always-on gateway. Container (podman) mode so the
# agent can self-install tools (apt/pip/npm) that persist across rebuilds —
# Hermes's whole self-improvement loop. Secrets (bot token, Anthropic key) are
# NOT nix/agenix on this keyless host: they're deposited over SSH as env files
# by `deposit-secrets` (see secret-deposit.nix) and read via environmentFiles.
#
# Supersedes the old openclaw/moltbot setup.
fp: {
  flake.modules.nixos.homeServer = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [fp.inputs.hermes-agent.nixosModules.default];

    services.hermes-agent = {
      enable = true;

      # Container mode: Ubuntu base, /nix/store bind-mounted read-only. The
      # server runs podman (base module), not docker.
      container = {
        enable = true;
        backend = "podman";
      };

      # Sealed-venv extras: `messaging` = python-telegram-bot (required for the
      # Telegram gateway); `anthropic` = native Anthropic SDK for talking to
      # api.anthropic.com directly. Both must be present at build time — Nix's
      # read-only store can't lazy-install them at runtime.
      extraDependencyGroups = ["messaging" "anthropic"];

      # Deposited by `deposit-secrets` (owner hermes:hermes, 0400). Merged into
      # $HERMES_HOME/.env at activation. telegram.env holds TELEGRAM_BOT_TOKEN +
      # TELEGRAM_ALLOWED_USERS; anthropic.env holds ANTHROPIC_API_KEY.
      environmentFiles = [
        "/var/lib/hermes-secrets/telegram.env"
        "/var/lib/hermes-secrets/anthropic.env"
      ];

      settings = {
        # Direct Anthropic API. The `anthropic` provider is selected explicitly
        # and keyed by ANTHROPIC_API_KEY (from anthropic.env) — it has its own
        # default endpoint, so NO base_url (that's only for OpenRouter/custom).
        # Native model IDs, no `anthropic/` routing prefix. Opus for replies,
        # cheap Haiku for context compression + session titles.
        model = {
          provider = "anthropic";
          default = "claude-opus-4-8";
        };
        toolsets = ["all"];
        # Send plain messages instead of Telegram-quoting each of Jean-Luc's
        # messages (the "↩ replying to…" UI). "off" suppresses the reply anchor;
        # alternatives are "first" (default, anchor on first chunk) / "all".
        platforms.telegram.reply_to_mode = "off";
        # Prefix every user message the model sees with a human-readable send
        # time, e.g. `[Tue 2026-04-28 13:40:53 PDT] …`. Off by default upstream;
        # this gives the agent temporal awareness of when each Telegram message
        # was sent (gaps, time-of-day) across replayed history + the live turn.
        gateway.message_timestamps.enabled = true;
        compression = {
          enabled = true;
          threshold = 0.85;
          summary_model = "claude-haiku-4-5-20251001";
        };
        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
        };
      };
    };
  };
}

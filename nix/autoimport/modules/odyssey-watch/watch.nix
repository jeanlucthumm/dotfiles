# Telegram alerts when new Odyssey IMAX showtimes appear at AMC Metreon 16.
#
# Lives on the server rather than a workstation for the obvious reason: a
# ten-minute poller is useless on a laptop that sleeps.
#
# Why this scrapes cinemaclock instead of AMC or Fandango, and what it can and
# cannot see, is documented at the top of _watch.py -- the constraints are
# properties of the data source, not of this module.
#
# The bot token and chat id arrive via `deposit-secrets odyssey-telegram` (see
# secrets/secrets.nix): this box is keyless and cannot be an agenix recipient,
# so the env file is decrypted on a hardware-key host and pushed over SSH.
#
# DynamicUser rather than a dedicated system user: systemd reads
# EnvironmentFile as root before dropping privileges, so the deposited secret
# can stay root-owned 0400 and no user needs managing. StateDirectory still
# gives the unit a stable /var/lib/odyssey-watch across runs.
{
  flake.modules.nixos.homeServer = {pkgs, ...}: let
    # Deliberately NOT under /var/lib/odyssey-watch: DynamicUser makes systemd
    # own that path as a symlink into /var/lib/private/, so a deposited file
    # sitting there would collide with StateDirectory setup.
    envFile = "/var/lib/odyssey-watch-secrets/telegram.env";

    watch = pkgs.writeShellScriptBin "odyssey-watch" ''
      exec ${pkgs.python3}/bin/python3 ${./_watch.py} "$@"
    '';
  in {
    # On the system PATH so the thing is debuggable by hand:
    #   odyssey-watch --show
    #   odyssey-watch --test-telegram      # needs the env file sourced
    environment.systemPackages = [watch];

    systemd.services.odyssey-watch = {
      description = "Check for new Odyssey IMAX showtimes at AMC Metreon 16";
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${watch}/bin/odyssey-watch";

        DynamicUser = true;
        StateDirectory = "odyssey-watch";
        StateDirectoryMode = "0700";

        # Optional so a missing deposit surfaces as the script's own explicit
        # error about which command to run, rather than an opaque systemd
        # failure. Matches the claude-agent unit's reasoning.
        EnvironmentFile = "-${envFile}";

        # Scraping a public page and POSTing to Telegram needs nothing else.
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      };
    };

    systemd.timers.odyssey-watch = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "10m";
        # Spread the polls off exact ten-minute boundaries; nothing here is
        # time-critical and it keeps the source from seeing a metronome.
        RandomizedDelaySec = "90s";
      };
    };
  };
}

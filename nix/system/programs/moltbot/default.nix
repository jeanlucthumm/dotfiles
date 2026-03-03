# Openclaw - Personal AI assistant (system service)
# https://github.com/openclaw/openclaw
#
# Runs as isolated system user with systemd hardening.
# Uses long-lived setup token from `claude setup-token`.
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-openclaw.nixosModules.openclaw
  ];

  age.secrets = {
    moltbot-telegram = {
      file = ../../../secrets/moltbot-telegram.age;
      owner = config.services.openclaw.user;
      group = config.services.openclaw.group;
    };
    moltbot-anthropic-token = {
      file = ../../../secrets/moltbot-anthropic-token.age;
      owner = config.services.openclaw.user;
      group = config.services.openclaw.group;
    };
  };

  services.openclaw = {
    enable = true;

    # Long-lived token from `claude setup-token`
    providers.anthropic.oauthTokenFile = config.age.secrets.moltbot-anthropic-token.path;

    # Model configuration
    defaults = {
      model = "anthropic/claude-opus-4-6";
      thinkingDefault = "high";
    };

    # Telegram channel
    providers.telegram = {
      enable = true;
      botTokenFile = config.age.secrets.moltbot-telegram.path;
      allowFrom = [7075644253];
    };

    # Gateway auth required by upstream (not exposed - only using Telegram)
    instances.default.gateway.auth = {
      mode = "token";
      tokenFile = "/var/lib/openclaw/gateway-token";
    };

    # Skills
    skills = [
      {
        name = "guided-day";
        mode = "copy";
        source = ./skills/guided-day;
      }
    ];
  };
}

# Moltbot - Personal AI assistant (system service)
# https://github.com/moltbot/moltbot
#
# Runs as isolated system user with systemd hardening.
# Uses long-lived setup token from `claude setup-token`.
{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-moltbot.nixosModules.moltbot
  ];

  age.secrets = {
    moltbot-telegram = {
      file = ../../../secrets/moltbot-telegram.age;
      owner = config.services.moltbot.user;
      group = config.services.moltbot.group;
    };
    moltbot-anthropic-token = {
      file = ../../../secrets/moltbot-anthropic-token.age;
      owner = config.services.moltbot.user;
      group = config.services.moltbot.group;
    };
  };

  services.moltbot = {
    enable = true;

    # Long-lived token from `claude setup-token`
    providers.anthropic.oauthTokenFile = config.age.secrets.moltbot-anthropic-token.path;

    # Model configuration
    defaults = {
      model = "anthropic/claude-opus-4-5";
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
      tokenFile = "/var/lib/moltbot/gateway-token";
    };
  };
}

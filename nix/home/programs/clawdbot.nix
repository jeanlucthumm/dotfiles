# Clawdbot - Personal AI assistant
# https://github.com/clawdbot/clawdbot
#
# Authentication: Uses Claude CLI OAuth credentials from ~/.claude/.credentials.json
# Run `claude` on the server and authenticate to set up credentials.
{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-clawdbot.homeManagerModules.clawdbot
  ];

  home.packages = [pkgs.claude-code];

  age.secrets.clawdbot-telegram.file = ../../secrets/clawdbot-telegram.age;

  programs.clawdbot = {
    enable = true;

    # Model configuration - uses Claude CLI OAuth credentials
    defaults = {
      model = "anthropic/claude-opus-4-5";
      thinkingDefault = "high";
    };

    # Disable macOS-only plugins
    firstParty.peekaboo.enable = false;
    firstParty.summarize.enable = false;

    instances.default = {
      # Telegram channel
      providers.telegram = {
        enable = true;
        botTokenFile = config.age.secrets.clawdbot-telegram.path;
        allowFrom = [7075644253];
      };

      # Auth profile for Claude CLI OAuth credentials
      configOverrides = {
        auth.profiles."anthropic:claude-cli" = {
          provider = "anthropic";
          mode = "oauth";
        };
      };
    };
  };
}

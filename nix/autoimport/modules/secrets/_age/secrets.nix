# TODO: agenix-rekey
let
  keys = import ../_pubkeys.nix;
  workstations = [keys.desktop.age keys.macbook.age];
  # Host key: the server's agenix decrypts with its SSH host keys by default.
  # Workstations stay recipients so secrets survive losing the server.
  withServer = workstations ++ [keys.server.hostKey];
in {
  "jeanluc-openai.age".publicKeys = workstations;
  "jeanluc-anthropic.age".publicKeys = workstations;
  "jeanluc-taskwarrior.age".publicKeys = workstations;
  "jeanluc-notion.age".publicKeys = workstations;

  "moltbot-telegram.age".publicKeys = withServer;
  "moltbot-anthropic-token.age".publicKeys = withServer;

  "claude-telegram.age".publicKeys = workstations;
  "odyssey-telegram.age".publicKeys = workstations;
  "zwave-js-keys.age".publicKeys = withServer;
}

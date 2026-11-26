# TODO: agenix-rekey
let
  keys = import ../_pubkeys.nix;
  # keys.desktop.age dropped 2026-11-11: desktop YubiKey lost. Re-add if found.
  workstations = [keys.macbook.age];
  # Host key: the server's agenix decrypts with its SSH host keys by default.
  # Workstations stay recipients so secrets survive losing the server.
  withServer = workstations ++ [keys.server.hostKey];
in {
  "jeanluc-openai.age".publicKeys = workstations;
  "jeanluc-anthropic.age".publicKeys = workstations;

  "claude-telegram.age".publicKeys = workstations;
  "chore-telegram.age".publicKeys = withServer;
  "zwave-js-keys.age".publicKeys = withServer;
  "ha-location-token.age".publicKeys = withServer;
}

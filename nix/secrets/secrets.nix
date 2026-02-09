let
  keys = import ./pubkeys.nix;
  # TODO: rename acc -> hwbacked
  # Hardware-backed secrets (YubiKey required to decrypt)
  acc = [keys.desktop.ssh keys.macbook.ssh];
  # Local-backed secrets (SSH key on disk, recoverable credentials only)
  localbacked = [keys.desktop.ssh keys.macbook.ssh keys.server];
in {
  # Hardware-backed (YubiKey)
  "jeanluc-openai.age".publicKeys = acc;
  "jeanluc-anthropic.age".publicKeys = acc;
  "jeanluc-tavily.age".publicKeys = acc;
  "jeanluc-codestral.age".publicKeys = acc;
  "jeanluc-taskwarrior.age".publicKeys = acc;
  "jeanluc-neo4j.age".publicKeys = acc;
  "jeanluc-ref.age".publicKeys = acc;
  "jeanluc-notion.age".publicKeys = acc;

  # Local-backed (recoverable, lower sensitivity)
  "moltbot-telegram.age".publicKeys = localbacked;
  "moltbot-anthropic-token.age".publicKeys = localbacked;
}

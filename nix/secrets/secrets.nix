let
  keys = import ./pubkeys.nix;
  workstations = [keys.desktop.age keys.macbook.age];
  withServer = workstations ++ [keys.server];
in {
  "jeanluc-openai.age".publicKeys = workstations;
  "jeanluc-anthropic.age".publicKeys = workstations;
  "jeanluc-tavily.age".publicKeys = workstations;
  "jeanluc-codestral.age".publicKeys = workstations;
  "jeanluc-taskwarrior.age".publicKeys = workstations;
  "jeanluc-neo4j.age".publicKeys = workstations;
  "jeanluc-ref.age".publicKeys = workstations;
  "jeanluc-notion.age".publicKeys = workstations;

  "moltbot-telegram.age".publicKeys = withServer;
  "moltbot-anthropic-token.age".publicKeys = withServer;
}

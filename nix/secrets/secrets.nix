let
  keys = import ./pubkeys.nix;
  acc = [keys.desktop keys.macbook];
in {
  "jeanluc-openai.age".publicKeys = acc;
  "jeanluc-anthropic.age".publicKeys = acc;
  "jeanluc-tavily.age".publicKeys = acc;
  "jeanluc-codestral.age".publicKeys = acc;
  "jeanluc-taskwarrior.age".publicKeys = acc;
  "jeanluc-neo4j.age".publicKeys = acc;
  "jeanluc-ref.age".publicKeys = acc;
}

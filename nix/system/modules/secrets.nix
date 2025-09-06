# System-level agenix secrets
# These are secrets needed by system services (vs user-level secrets in home manager)
{
  pkgs,
  config,
  ...
}: {
  age.secrets = {
    jeanluc-neo4j = {
      file = ../../secrets/jeanluc-neo4j.age;
      owner = "neo4j";
      group = "wheel";
      mode = "0640"; # readable by owner and group
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "get-key-neo4j" ''
      cat ${config.age.secrets.jeanluc-neo4j.path}
    '')
  ];
}
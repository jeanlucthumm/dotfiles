# Crypto, auth, SSH, security, etc.
{
  pkgs,
  config,
  ...
}: {
  age = {
    secrets = {
      openai = {
        file = ../../secrets/jeanluc-openai.age;
        mode = "400";
      };
      anthropic = {
        file = ../../secrets/jeanluc-anthropic.age;
        mode = "400";
      };
      tavily = {
        file = ../../secrets/jeanluc-tavily.age;
        mode = "400";
      };
      codestral = {
        file = ../../secrets/jeanluc-codestral.age;
        mode = "400";
      };
    };
    # Allows agenix to use user ssh keys
    identityPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519"
    ];
  };

  home.packages = let
    s = config.age.secrets;
    makeKeyGetter = path: ''
      umask 077 # Ensure any possible temp files are private
      cat ${path}
    '';
  in [
    (
      pkgs.writeShellScriptBin
      "get-key-anthropic" (makeKeyGetter s.anthropic.path)
    )
    (
      pkgs.writeShellScriptBin
      "get-key-openai" (makeKeyGetter s.openai.path)
    )
    (
      pkgs.writeShellScriptBin
      "get-key-tavily" (makeKeyGetter s.tavily.path)
    )
    (
      pkgs.writeShellScriptBin
      "get-key-codestral" (makeKeyGetter s.codestral.path)
    )
  ];
}

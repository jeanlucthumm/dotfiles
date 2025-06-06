# Crypto, auth, SSH, security, etc.
{config, ...}: {
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
    };
    # Allows agenix to use user ssh keys
    identityPaths = [
      "${config.home.homeDirectory}/.ssh/id_ed25519"
    ];
  };
}

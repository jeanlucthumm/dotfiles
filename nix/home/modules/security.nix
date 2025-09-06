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
      taskwarrior = {
        file = ../../secrets/jeanluc-taskwarrior.age;
        mode = "400";
        # Workaround since taskwarrior config does not support shell eval
        # And Darwin `path` includes it.
        path = "/tmp/jeanluc-taskwarrior.age";
        # Workaround for lack of lchmod on Darwin, so symlinks wouldn't have correct `mode`.
        symlink = false;
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
  in
    with pkgs; [
      # Key Getters
      (pkgs.writeShellScriptBin "get-key-anthropic" (makeKeyGetter s.anthropic.path))
      (pkgs.writeShellScriptBin "get-key-openai" (makeKeyGetter s.openai.path))
      (pkgs.writeShellScriptBin "get-key-tavily" (makeKeyGetter s.tavily.path))
      (pkgs.writeShellScriptBin "get-key-codestral" (makeKeyGetter s.codestral.path))

      gnupg # GNU Privacy Guard
      pinentry-tty # Enter password in terminal
    ];
}

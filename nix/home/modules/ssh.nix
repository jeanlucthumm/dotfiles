# SSH setup.
# Note: this is not required for Darwin since launchd handles SSH stuff.
{lib, ...}: {
  programs = {
    nushell.environmentVariables.SSH_AUTH_SOCK = lib.hm.nushell.mkNushellInline ''$"($env.XDG_RUNTIME_DIR)/ssh-agent"'';

    ssh.matchBlocks.server = {
      host = "server server.lan";
      controlMaster = "auto";
      controlPath = "~/.ssh/sockets/%r@%h-%p";
      controlPersist = "4h";
    };
  };
}

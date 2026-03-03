# Darwin-specific SSH setup: FIDO2-capable openssh, agent, and lazy key loading.
{pkgs, ...}: {
  home.packages = with pkgs; [
    openssh # FIDO2-capable SSH (macOS system SSH lacks libfido2)
  ];

  # Use nix-provided ssh-agent instead of macOS launchd agent (which lacks SK/FIDO2 support)
  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.ssh = {
    addKeysToAgent = "yes";

    matchBlocks."*".identityFile = "~/.ssh/id_ed25519_sk_auth";
  };

  # Point system-wide SSH_AUTH_SOCK to FIDO2-capable agent so GUI apps use it.
  # Keys are loaded lazily via AddKeysToAgent; git signing uses the key file directly.
  launchd.agents.ssh-fido2-setup = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          SOCK="$(getconf DARWIN_USER_TEMP_DIR)ssh-agent"
          launchctl setenv SSH_AUTH_SOCK "$SOCK"
        ''
      ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}

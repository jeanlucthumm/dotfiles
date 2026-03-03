# Darwin-specific SSH setup: FIDO2-capable openssh, agent, and key preloading.
{pkgs, ...}: {
  home.packages = with pkgs; [
    openssh # FIDO2-capable SSH (macOS system SSH lacks libfido2)
  ];

  # Use nix-provided ssh-agent instead of macOS launchd agent (which lacks SK/FIDO2 support)
  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
  };

  # Point system-wide SSH_AUTH_SOCK to FIDO2-capable agent, preload auth key.
  launchd.agents.ssh-fido2-setup = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/bash"
        "-c"
        ''
          SOCK="$(getconf DARWIN_USER_TEMP_DIR)ssh-agent"
          launchctl setenv SSH_AUTH_SOCK "$SOCK"
          while [ ! -S "$SOCK" ]; do sleep 0.5; done
          export SSH_AUTH_SOCK="$SOCK"
          ${pkgs.openssh}/bin/ssh-add "$HOME/.ssh/id_ed25519_sk_auth" 2>/dev/null
        ''
      ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}

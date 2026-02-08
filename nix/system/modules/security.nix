# Crypto, auth, SSH, security, etc.
{pkgs, ...}: {
  programs = {
    # Manages GPG keys for signing stuff like git commits
    gnupg.agent = {
      enable = true;
      # Use the CLI to provide key passwords
      pinentryPackage = pkgs.pinentry-tty;
      settings = {
        # Don't ask for password within given time
        default-cache-ttl = 14400;
        max-cache-ttl = 14400;
        # Prevent scdaemon from grabbing YubiKey CCID interface (conflicts with pcscd)
        disable-scdaemon = true;
      };
    };

    # Manages SSH keys so you can do `ssh-add`
    ssh.startAgent = true;
  };

  security = {
    # Privilege escalation for user programs
    polkit.enable = true;

    # Allow wheel group users to mount drives without password
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        var YES = polkit.Result.YES;
        var permission = {
          "org.freedesktop.udisks2.filesystem-mount": YES,
          "org.freedesktop.udisks2.filesystem-mount-system": YES,
          "org.freedesktop.udisks2.eject-media": YES,
          "org.freedesktop.udisks2.power-off-drive": YES
        };
        if (subject.isInGroup("wheel")) {
          return permission[action.id];
        }
      });
    '';
  };
}

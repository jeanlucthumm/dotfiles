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
        # NB: = true renders as "disable-scdaemon true" which crashes gpg-agent.
        # Empty string renders as bare flag. See https://github.com/NixOS/nixpkgs/issues/488446
        disable-scdaemon = "";
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

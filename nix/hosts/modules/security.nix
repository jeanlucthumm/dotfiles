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
      };
    };

    # Manages SSH keys so you can do `ssh-add`
    ssh.startAgent = true;
  };

  services = {
    # Manages program secrets.
    gnome.gnome-keyring.enable = true;
  };

  security = {
    # Unlock gnome-keyring on tty login
    pam.services.login.enableGnomeKeyring = true;

    # Privilege escalation for user programs
    polkit.enable = true;
  };
}

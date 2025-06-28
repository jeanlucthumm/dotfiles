# SSH is a widely used client/server for secure shell connections.
{lib, ...}: {
  services.openssh = {
    enable = true;
    # Forces SSH keys which is more secure than passwords
    settings.PasswordAuthentication = false;
  };
  networking.firewall.allowedTCPPorts = [22];

  services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
}

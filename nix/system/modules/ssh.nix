# SSH is a widely used client/server for secure shell connections.
{...}: {
  services.openssh = {
    enable = true;
    # Forces SSH keys which is more secure than passwords
    settings.PasswordAuthentication = false;
  };
  firewall.allowedTCPPorts = [22];
}

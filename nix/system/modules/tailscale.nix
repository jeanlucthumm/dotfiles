# Tailscale is a VPN that makes it easy to connect your devices to your home network.
{...}: {
  networking.firewall.allowedUDPPorts = [41641];
  networking.firewall.checkReversePath = false;
  services.tailscale.enable = true;
  boot.kernelParams = [
    # Allows a Linux system to forward packets from one network interface to another,
    # which is necessary for routing traffic between Tailscale and the rest of the network.
    "net.ipv4.ip_forward=1"
  ];
}

{...}: {
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = ["/var/lib/home-assistant:/config"];
      environment.TZ = "America/Los_Angeles"; # Adjust timezone as needed
      image = "ghcr.io/home-assistant/home-assistant:stable";
      extraOptions = [
        "--network=host"
      ];
    };
  };

  # Ensure Home Assistant directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0755 root root -"
  ];

  # Open Home Assistant port
  networking.firewall.allowedTCPPorts = [8123];
}

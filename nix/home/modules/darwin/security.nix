{pkgs, ...}: {
  home.packages = with pkgs; [
    openssh # FIDO2-capable SSH (macOS system SSH lacks libfido2)
  ];

  # Use nix-provided ssh-agent instead of macOS launchd agent (which lacks SK/FIDO2 support)
  services.ssh-agent = {
    enable = true;
    enableNushellIntegration = true;
  };
}

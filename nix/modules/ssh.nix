{
  flake.modules.darwin.ssh = {
    # SSH server configuration
    services.openssh = {
      enable = true;
      extraConfig = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
      '';
    };
  };
}

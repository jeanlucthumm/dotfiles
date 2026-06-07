# SSH & auth setup for security key based hosts
fp: {
  flake.modules.generic.secrets = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.age-plugin-yubikey
    ];

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.secrets];
  };

  flake.modules.nixos.secrets = {pkgs, ...}: {
    # PCSC daemon for smart card support (Yubikey)
    service.pscd.enable = true;

    home-manager.sharedModules = [fp.config.flake.modules.homeManager.secrets];
  };

  flake.modules.homeManager.secrets = {pkgs, ...}: {
    home.packages = with pkgs; [
      yubikey-manager # ykman CLI
      age-plugin-yubikey # PIV-backed age identities
    ];

    # Security identity
    programs.git.signing = {
      key = "~/.ssh/id_ed25519_sk_signing";
      format = "ssh";
    };

    home.sessionVariables = {
      HW_KEY_HOST = true;
    };
  };
}

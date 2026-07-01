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
    services.pcscd.enable = true;

    # NOTE: homeManager.secrets is injected into home-manager.sharedModules by
    # secrets.nix's nixos.secrets. Do not inject it here too -- a duplicate
    # import makes the module system declare jl.secretDeposit options twice.
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

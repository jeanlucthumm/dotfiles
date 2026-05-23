# SSH & auth setup for security key based hosts
{...}: {
  flake.modules.generic.secrets = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.age-plugin-yubikey
    ];
  };

  flake.modules.homeManager.secrets = {pkgs, ...}: {
    home.packages = with pkgs; [
      yubikey-manager # ykman CLI
      age-plugin-yubikey # PIV-backed age identities
    ];

    home.sessionVariables = {
      HW_KEY_HOST = true;
    };
  };
}

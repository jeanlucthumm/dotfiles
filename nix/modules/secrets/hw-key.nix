# SSH & auth setup for security key based hosts
{...}: {
  flake.modules.generic.hwKey = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.age-plugin-yubikey
    ];
  };

  flake.modules.homeManager.hwKey = {pkgs, ...}: {
    home.packages = with pkgs; [
      yubikey-manager # ykman CLI
      age-plugin-yubikey # PIV-backed age identities
    ];
  };
}

# Full nushell config - imports foundation + qol + dev
{...}: {
  imports = [
    ./foundation.nix
    ./qol.nix
    ./dev.nix
  ];
}

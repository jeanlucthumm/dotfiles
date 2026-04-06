# CLI module - imports all CLI-related configurations
{
  imports = [
    ./foundation.nix
    ./dev.nix
    ./dev-custom.nix
    ./qol.nix
    ./qol-system.nix
    ./sysadmin.nix
  ];
}

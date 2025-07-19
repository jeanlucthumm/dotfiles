# Modules

This is the place for custom config modules (for both the system and HM config).

These are meant to be used in import statements:

```nix
{pkgs, config, ...}:
{
  imports = [
    ./modules/something.nix
  ];

  something = {...};
}
```

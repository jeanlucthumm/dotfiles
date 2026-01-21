# Logitech MX Master mouse support
# Provides udev rules and Solaar for device access
# Button remapping configured via home-manager (home/programs/solaar.nix)
{...}: {
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;
}

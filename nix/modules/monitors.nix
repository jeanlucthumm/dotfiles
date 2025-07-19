# NixOS module to standardize monitor information
{lib, ...}: let
  monitor = lib.types.submodule {
    options = {
      manufacturer = lib.mkOption {
        type = lib.types.str;
        description = "In 'Shenzhen KTC Technology Group M32P10 0000000000001', this is 'Shenzhen KTC Technology Group'.";
      };
      model = lib.mkOption {
        type = lib.types.str;
        description = "In 'Shenzhen KTC Technology Group M32P10 0000000000001', this is 'M32P10'.";
      };
      serial = lib.mkOption {
        type = lib.types.str;
        description = "In 'Shenzhen KTC Technology Group M32P10 0000000000001', this is '0000000000001'.";
      };
      width = lib.mkOption {
        type = lib.types.int;
        description = "Width of the monitor in pixels.";
      };
      height = lib.mkOption {
        type = lib.types.int;
        description = "Height of the monitor in pixels.";
      };
      refresh = lib.mkOption {
        type = lib.types.float;
        description = "Refresh rate of the monitor in Hz.";
      };
      rotation = lib.mkOption {
        type = lib.types.enum [0 90 180 270];
        default = 0;
        description = "Counter-clockwise rotation of the monitor in degrees.";
      };
      position_x = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "X position of the monitor in pixels.";
      };
      position_y = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Y position of the monitor in pixels.";
      };
    };
  };
in {
  options.monitors = {
    primary = lib.mkOption {
      description = "Primary monitor configuration.";
      type = monitor;
    };
    secondary = lib.mkOption {
      description = "Secondary monitor configuration.";
      type = lib.types.nullOr monitor;
      default = null;
    };
  };
}

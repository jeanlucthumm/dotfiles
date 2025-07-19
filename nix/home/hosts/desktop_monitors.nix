{...}: {
  imports = [
    ../../modules/monitors.nix
  ];

  monitors.primary = {
    manufacturer = "Shenzhen KTC Technology Group";
    model = "M32P10";
    serial = "0000000000001";
    width = 3840;
    height = 2160;
    refresh = 144.0;
    rotation = 0;
    position_x = 0;
    position_y = 0;
  };

  monitors.secondary = {
    manufacturer = "PNP(AOC)";
    model = "U2790B";
    serial = "0x00029BC0";
    width = 3840;
    height = 2160;
    refresh = 60.0;
    rotation = 270;
    position_x = 3840;
    position_y = -900;
  };
}

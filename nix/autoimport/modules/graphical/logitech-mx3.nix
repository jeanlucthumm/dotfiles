fp @ {jlib, ...}: {
  flake.modules.nixos.graphical = {
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;
  };

  flake.modules.homeManager.graphical = jlib.mkHomeManager {
    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: {
      imports = [
        fp.config.flake.modules.homeManager.opt-solaar
      ];

      programs.solaar = {
        enable = true;

        devices."MX Master 3S" = {
          modelId = "B03400000000";
          serial = "EB5ACC14";
          unitId = "EB5ACC14";
          wpid = "B034";
          divertButtons = [195]; # 195 = Mouse Gesture Button (thumb)
        };

        rules = [
          {
            button = "Mouse Gesture Button";
            state = "pressed";
            keyPress = ["Super_L" "Shift_L" "F10"];
          }
        ];
      };
    };
  };
}

# Logitech MX Master 3S configuration
# Maps thumb (gesture) button to Super+Shift+F10 for niri overview toggle
{...}: {
  imports = [../options/solaar.nix];

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
}

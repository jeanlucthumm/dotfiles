{
  system.defaults.NSGlobalDomain = {
    InitialKeyRepeat = 10;
    KeyRepeat = 1;
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "34" = {
          # Show application windows (Ctrl+Down)
          enabled = true;
          value = {
            parameters = [65535 125 2359296];
            type = "standard";
          };
        };
        "27" = {
          # Move focus to next window (Cmd+`)
          enabled = true;
          value = {
            parameters = [96 50 1048576];
            type = "standard";
          };
        };
        "222" = {
          # Toggle Stage Manager (Cmd+Shift+I)
          enabled = true;
          value = {
            parameters = [105 34 1179648];
            type = "standard";
          };
        };
      };
    };
  };
}

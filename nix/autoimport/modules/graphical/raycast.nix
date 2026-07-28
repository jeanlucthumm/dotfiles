# Raycast (package added in graphical.nix)
_: {
  flake.modules.darwin.graphical = {
    system.defaults.CustomUserPreferences = {
      "com.raycast.macos" = {
        # Bind Cmd+Space (keycode 49 = Space) as the global hotkey.
        # Raycast reads this on launch, so it needs a restart after activation.
        raycastGlobalHotkey = "Command-49";
      };
      # Free up the hotkey from Spotlight. Takes effect after logout/login.
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # Disable Spotlight search (Cmd+Space)
          "64".enabled = false;
          # Disable Finder search window (Cmd+Option+Space)
          "65".enabled = false;
        };
      };
    };
  };
}

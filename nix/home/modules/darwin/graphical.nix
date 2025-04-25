# Darwin specific GUI settings
{...}: {
  # These are darwin specific because NixOS relies on the WM for splits.
  programs.kitty = {
    settings = {
      macos_option_as_alt = true;
    };
    keybindings = {
      "cmd+p" = "previous_tab";
      "cmd+n" = "next_tab";
      "cmd+k" = "focus_visible_window";
      "cmd+shift+n" = "new_os_window";
      "cmd+h" = "previous_window";
      "cmd+l" = "next_window";
    };
  };
}

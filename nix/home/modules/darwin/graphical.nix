# Darwin specific GUI settings
{config, ...}: {
  # These are darwin specific because NixOS relies on the WM for splits.
  programs = {
    kitty = {
      settings = {
        macos_option_as_alt = true;
        macos_titlebar_color = "background";
        # macOS GUI apps don't inherit shell PATH, so tell kitty where to find nvim
        exe_search_path = "/etc/profiles/per-user/${config.home.username}/bin";
      };
      keybindings = {
        "cmd+p" = "previous_tab";
        "cmd+n" = "next_tab";
        "cmd+shift+p" = "move_tab_backward";
        "cmd+shift+n" = "move_tab_forward";
        "cmd+k" = "focus_visible_window";
        "cmd+shift+r" = "set_tab_title";
        "cmd+h" = "previous_window";
        "cmd+l" = "next_window";
        "cmd+enter" = "new_window_with_cwd";
      };
    };
    nushell.shellAliases.nv = "neovide --frame transparent --fork";
  };
}

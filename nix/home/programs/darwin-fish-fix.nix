{lib, ...}: {
  # This is needed to address bug where the $PATH is re-ordered by
  # the `path_helper` tool, prioritising Apple’s tools over the ones we’ve
  # installed with nix.
  #
  # This gist explains the issue in more detail: https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
  # There is also an issue open for nix-darwin: https://github.com/LnL7/nix-darwin/issues/122
  programs.fish.loginShellInit = let
    # We should probably use `config.environment.profiles`, as described in
    # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1659465635
    # but this takes into account the new XDG paths used when the nix
    # configuration has `use-xdg-base-directories` enabled. See:
    # https://github.com/LnL7/nix-darwin/issues/947 for more information.
    profiles = [
      "/etc/profiles/per-user/$USER" # Home manager packages
      "$HOME/.nix-profile"
      "(set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $HOME/.local/state)/nix/profile"
      "/run/current-system/sw"
      "/nix/var/nix/profiles/default"
    ];

    makeBinSearchPath =
      lib.concatMapStringsSep " " (path: "${path}/bin");
  in ''
    # Fix path that was re-ordered by Apple's path_helper
    fish_add_path --move --prepend --path ${makeBinSearchPath profiles}
    set fish_user_paths $fish_user_paths
  '';
}

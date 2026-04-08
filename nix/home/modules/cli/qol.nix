# Quality of life CLI setup - modern shell niceties for any machine
{pkgs, ...}: let
  clip = pkgs.writeShellScriptBin "clip" ''
    if [ -n "$TMUX" ]; then
      tmux loadb -
    elif [ "$(uname)" = "Darwin" ]; then
      pbcopy
    elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
      wl-copy
    else
      xclip -selection clipboard
    fi
  '';

  paste = pkgs.writeShellScriptBin "paste" ''
    if [ -n "$TMUX" ]; then
      tmux showb -t 0
    elif [ "$(uname)" = "Darwin" ]; then
      pbpaste
    elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
      wl-paste
    else
      xclip -selection clipboard -o
    fi
  '';

  copy-last-cmd = pkgs.writeShellScriptBin "copy-last-cmd" ''
    cmd=$(${pkgs.nushell}/bin/nu -c 'history | last | get command')
    output=$(kitty @ get-text --extent last_non_empty_output)
    printf '$ %s\n%s' "$cmd" "$output" | ${clip}/bin/clip
  '';
in {
  imports = [
    ../../programs/starship.nix
    ../../programs/nushell/qol.nix
  ];

  home.packages = with pkgs; [
    fzf # Multi-purpose fuzzy finder

    # Modern replacements for common tools
    fd # find replacement
    dust # du replacement
    eza # ls replacement
    ripgrep # grep replacement
    bat-extras.batman # man replacement
    sd # sed replacement

    # Clipboard utilities
    clip
    paste
    copy-last-cmd
  ];

  programs = {
    carapace.enable = true;
    bat.enable = true; # cat replacement
    direnv.enable = true;
    zoxide.enable = true; # cd replacement

    yazi = {
      enable = true;
      plugins = {
        "rsync" = pkgs.yaziPlugins.rsync;
        "smart-filter" = pkgs.yaziPlugins.smart-filter;
      };
      keymap.mgr.prepend_keymap = [
        {
          on = ["<C-i>"];
          run = "forward";
          desc = "Go forward to next directory";
        }
        {
          on = ["<C-o>"];
          run = "back";
          desc = "Go back to previous directory";
        }
        {
          on = ["R"];
          run = "plugin rsync";
          desc = "Copy files using rsync";
        }
        {
          on = ["F"];
          run = "plugin smart-filter";
          desc = "Filter files using smart filter";
        }
        {
          on = ["c" "y"];
          run = ''shell --block -- sh -c "cat \"$1\" | ${clip}/bin/clip"'';
          desc = "Copy file contents to clipboard";
        }
      ];
    };
  };

  home = {
    preferXdgDirectories = true;
    sessionVariables = {
      MANPAGER = "sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'";
    };
  };
  xdg.enable = true;
}

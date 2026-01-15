# Quality of life CLI setup - nicer interactive experience
{pkgs, ...}: {
  imports = [
    ../../programs/starship.nix
  ];

  home.packages = with pkgs; [
    notify # Cross-platform notifications
    fzf # Multi-purpose fuzzy finder
    ffmpeg
    usbutils # USB utilities

    # Modern replacements for common tools
    delta # Pretty diffs
    fd # find replacement
    dust # du replacement
    eza # ls replacement
    ripgrep # grep replacement
    bat-extras.batman # man replacement
    sd # sed replacement
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
          run = ''shell --block -- ${pkgs.nushell}/bin/nu --login -c "cat \"$1\" | clip"'';
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

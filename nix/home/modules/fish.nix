{
  config,
  pkgs,
  lib,
  ...
}: let
  isArch = builtins.pathExists "/etc/arch-release";
in {
  programs.fish = {
    enable = true;
    plugins = with pkgs.fishPlugins; [
      {
        name = "fzf";
        src = fzf;
      }
      {
        name = "grc";
        src = grc;
      }
      {
        name = "agnoster";
        src = pkgs.fetchFromGitHub {
          owner = "jeanlucthumm";
          repo = "theme-agnoster";
          rev = "502ff4f34224c9aa90a8d0a3ad517940eaf4d4fd";
          sha256 = "12gc6mw5cb3pdqp8haqx9abgjw64v3960g0f0hgb122xa3z7qldm";
        };
      }
    ];
    shellAbbrs = {
      g = "git";
      t = "task";
      docker = "sudo docker";
      ga = "git add -A";
      gm = "git commit -m";
      ym = "yadm commit -m";
      gs = "git stat";
      gt = "git tree";
      gd = "git d";
      gda = "git add -A && git d";
      yda = "yadm add -u -p && yadm d";
      clear-nvim-swap = "rm -rf ~/.local/state/nvim/swap";
      ta = "task active";
      tr = "task ready";
      tdesc = "tprop description";
      day = "timew day";
      acc = "task end.after:today completed";
    };
    # Like shellAbbrs but doesn't auto expand when typing
    shellAliases =
      {
        vim = "nvim";
        cat = "bat";
        ls = "pls --exclude '^\\..*'";
        lsa = "pls";
        cd = "z";
        ssh = "TERM=xterm-256color /usr/bin/ssh";
      }
      // lib.mkIf isArch {
        pacman = "paru";
      };
    shellInit = ''
      # Required for zoxide.
      # Do not put in interactiveShellInit due to bug.
      # Needs to be first.
      ${pkgs.zoxide}/bin/zoxide init fish | source
    '';
    interactiveShellInit = ''
      # Jump around words easier
      bind \ch backward-word
      bind \cl forward-word

      # Theme (majority is set by stylix)
      set -g theme_nerd_fonts yes
      set -g theme_virtual_env_prompt_enabled no

      if [ "$TERM" = "xterm-kitty" ]
          abbr --add -- icat 'kitty +kitten icat'
          alias newterm='kitty --detach --directory (pwd)'
      end

      if is_ssh_session; and not set -q TMUX
        exec tmux attach
      end
    '';
  };
}
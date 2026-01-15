# Devving related CLI setup
{
  config,
  pkgs,
  ...
}: let
  configDir = config.xdg.configHome;
in {
  imports = [
    ../../programs/nushell/dev.nix
  ];

  home.packages = with pkgs; [
    timewarrior # time tracker
    taskwarrior-enhanced # Enhanced taskwarrior companion CLI
    gh # GitHub CLI
    git # Version control system
    git-lfs # Git extension for large files
    git-filter-repo # Git tool for rewriting history
    git-crypt # Encrypt files in git repos
    gnumake # Build automation tool
    entr # Run arbitrary commands when files change
    devenv # Development environment manager
    just # Handy task runner
    notion-cli # Notion API CLI
    doppler # Secrets manager
    difit # GitHub-style git diff viewer
    lua-language-server # Lua language server
    tree-sitter # Syntax parser extensively used by NeoVim
    mdformat # Markdown formatter
    gcc # GNU Compiler Collection
  ];

  programs = {
    git = {
      enable = true;
      signing = {
        key = "6887D29E72EBFA1A0785A02A6717084E580D97E0";
        signByDefault = true;
      };
      includes = [
        {
          path = "${configDir}/delta/themes.gitconfig";
        }
      ];
      ignores = [
        ".DS_Store"
      ];
      settings = {
        user = {
          email = "jeanlucthumm@gmail.com";
          name = "Jean-Luc Thumm";
        };
        alias = {
          de = "diff";
          s = "status";
          stat = "status";
          d = "diff --cached";
          tree = "log --graph --decorate --oneline --all -n 25";
          treel = "log --graph --decorate --oneline --all";
          check = "checkout";
          head = "symbolic-ref --short HEAD";
          ignore = "!gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}; gi";
        };
        merge = {
          tool = "meld";
          conflictstyle = "diff3";
        };
        "mergetool \"meld\"" = {
          cmd = ''meld --auto-merge "$LOCAL" "$BASE" "$REMOTE" --output "$MERGED"'';
        };
        credential.helper = "cache";
        safe.directory = "/opt/flutter";
        pull.rebase = true;
        rebase.merges = true;
        init.defaultBranch = "master";
        diff.context = 15;
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = false;
      };
    };

    # GitHub CLI
    gh = {
      enable = true;
      # Allows git to defer to gh for authenticating with GitHub repoes
      gitCredentialHelper = {
        enable = true;
        hosts = [
          "https://github.com"
          "https://gist.github.com"
        ];
      };
      settings = {
        git_protocol = "ssh";
        # Run with `gh [alias]`
        aliases = {
          # Wait until PR checks return with success or error
          watch = "pr checks --watch";
        };
      };
    };
  };
}

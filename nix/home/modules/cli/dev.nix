# Core development tools - essentials for any dev machine
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
    gh # GitHub CLI
    git # Version control system
    git-lfs # Git extension for large files
    git-filter-repo # Git tool for rewriting history
    git-crypt # Encrypt files in git repos
    devenv # Development environment manager
    gnumake # Build automation tool
    entr # Run arbitrary commands when files change
    just # Handy task runner
    lua-language-server # Lua language server
    tree-sitter # Syntax parser extensively used by NeoVim
    mdformat # Markdown formatter
    gcc # GNU Compiler Collection
    graphite-cli # Stacked branch management
  ];

  programs = {
    git = {
      enable = true;
      signing.signByDefault = true;
      # signing.key and signing.format set per-host (FIDO2 YubiKey, differs per device)
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

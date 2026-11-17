{
  flake.modules.homeManager.graphical = {lib, ...}: {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      settings = let
        # Colors are palette names (palettes come from theme/home.nix): primary
        # accent (c1) then a gray gradient fading right. Darker segments (left)
        # get `text`, lighter ones (right) get `text_alt`, emphasizing
        # directory and git.
        langSymbols = {
          elixir = "";
          elm = "";
          golang = "";
          gradle = "";
          haskell = "";
          java = "";
          julia = "";
          nodejs = "";
          nim = "󰆥";
          rust = "";
          scala = "";
          dart = "";
        };

        makeLanguageConfig = name: symbol: {
          inherit symbol;
          style = "bg:c4 fg:text_alt";
          format = "[ $symbol ($version) ]($style)";
        };
      in
        {
          format = lib.strings.concatStrings [
            "[](c1)"
            "$hostname"
            "[](bg:c2 fg:c1)"
            "$directory"
            "[](fg:c2 bg:c3)"
            "$vcs"
            "[](fg:c3 bg:c4)"
            "$c"
            "$elixir"
            "$elm"
            "$golang"
            "$gradle"
            "$haskell"
            "$java"
            "$julia"
            "$nix_shell"
            "$nodejs"
            "$nim"
            "$rust"
            "$scala"
            "$dart"
            "[ ](fg:c4)"
          ];

          hostname = {
            ssh_only = true;
            format = "[ $hostname ]($style)";
            style = "bg:c1 fg:text";
          };

          directory = {
            style = "bg:c2 fg:text";
            format = "[ $path ]($style)";
            truncation_length = 3;
            truncation_symbol = "…/";
            substitutions = {
              "Documents" = "󰈙 ";
              "Downloads" = " ";
              "Music" = " ";
              "Pictures" = " ";
              "Code" = " ";
            };
          };

          git_branch = {
            symbol = "";
            style = "bg:c3 fg:text";
            format = "[ $symbol $branch ]($style)";
            truncation_length = 24;
            truncation_symbol = "…";
          };

          git_status = {
            style = "bg:c3 fg:text";
            format = "[$all_status$ahead_behind ]($style)";
          };

          # jj first: a colocated repo is also a git repo, where git only
          # sees a detached HEAD.
          vcs = {
            order = ["jj" "git"];
            git_modules = "$git_branch$git_status";
            jj_modules = "$jj_bookmark$jj_change$jj_status";
          };

          # Bookmark on @ or @-, if any.
          jj_bookmark = {
            style = "bg:c3 fg:text";
            format = "[ $symbol$bookmark]($style)";
            truncation_length = 24;
          };

          # Change id, shortest unique prefix in bold.
          jj_change = {
            prefix_style = "bg:c3 fg:text bold";
            suffix_style = "bg:c3 fg:text";
            change_offset_style = "bg:c3 fg:text bold";
            format = "[ ](bg:c3)$change[ ](bg:c3)";
          };

          # Nothing for a missing description: that is the normal state mid-work.
          # Each symbol carries its own trailing space.
          jj_status = {
            style = "bg:c3 fg:text";
            format = "([$all]($style))";
            description_empty = "";
            conflicted = "! ";
            immutable = "◆ ";
            added = "+$count ";
            modified = "~$count ";
            deleted = "−$count ";
            renamed = "→$count ";
            copied = "=$count ";
          };

          nix_shell = {
            symbol = "󱄅";
            style = "bg:c4 fg:text_alt";
            format = "[ $symbol ]($style)";
          };
        }
        // builtins.mapAttrs makeLanguageConfig langSymbols;
    };
  };
}

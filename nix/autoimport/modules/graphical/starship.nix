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
            "$git_branch"
            "$git_status"
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

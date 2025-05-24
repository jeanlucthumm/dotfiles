{
  config,
  lib,
  ...
}: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    settings = let
      fg =
        if config.stylix.enable
        then config.lib.stylix.colors.base00
        else "#FBF1C7";
      # Colors
      c1 = "#9A348E";
      c2 = "#DA627D";
      c3 = "#FCA17D";
      c4 = "#86BBD8";
      c5 = "#06969A";

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
        style = "bg:${c4} fg:${fg}";
        format = "[ $symbol ($version) ]($style)";
      };
    in
      {
        format = lib.strings.concatStrings [
          "[](${c1})"
          "$os"
          "$username"
          "[](bg:${c2} fg:${c1})"
          "$directory"
          "[](fg:${c2} bg:${c3})"
          "$git_branch"
          "$git_status"
          "[](fg:${c3} bg:${c4})"
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
          "[ ](fg:${c4})"
        ];

        os = {
          style = "bg:${c1}";
        };

        directory = {
          style = "bg:${c2} fg:${fg}";
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
          style = "bg:${c3} fg:${fg}";
          format = "[ $symbol $branch ]($style)";
        };

        git_status = {
          style = "bg:${c3} fg:${fg}";
          format = "[$all_status$ahead_behind ]($style)";
        };

        nix_shell = {
          symbol = "󱄅";
          style = "bg:${c4} fg:${fg}";
          format = "[ $symbol ]($style)";
        };
      }
      // builtins.mapAttrs makeLanguageConfig langSymbols;
  };
}

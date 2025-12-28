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
      stylixEnabled = config ? stylix && config.stylix.enable;
      colors = config.lib.stylix.colors.withHashtag;
      # Foreground for gray segments (light)
      fg =
        if stylixEnabled
        then colors.base00
        else "#FBF1C7";
      # Foreground for accent segment (dark for contrast)
      fgAccent =
        if stylixEnabled
        then colors.base07
        else "#282828";
      # Segment colors: accent + gray gradient
      c1 =
        if stylixEnabled
        then colors.base0D # primary accent (blue)
        else "#9A348E";
      c2 =
        if stylixEnabled
        then colors.base02 # gray - selection bg
        else "#DA627D";
      c3 =
        if stylixEnabled
        then colors.base03 # gray - comments
        else "#FCA17D";
      c4 =
        if stylixEnabled
        then colors.base04 # gray - dark fg
        else "#86BBD8";

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
          style = "bg:${c1} fg:${fg}";
        };

        directory = {
          style = "bg:${c2} fg:${fgAccent}";
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

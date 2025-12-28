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
      # Segment colors: primary accent (c1) then gray gradient fading right.
      # Darker segments (left) get light text, lighter segments (right) get dark text.
      # This emphasizes the more important leftward segments (directory, git).
      fg =
        if stylixEnabled
        then colors.base00
        else "#FBF1C7";
      fgAccent =
        if stylixEnabled
        then colors.base07
        else "#282828";
      c1 =
        if stylixEnabled
        then colors.base0D # primary accent
        else "#9A348E";
      c2 =
        if stylixEnabled
        then colors.base04 # darker gray
        else "#DA627D";
      c3 =
        if stylixEnabled
        then colors.base03 # medium gray
        else "#FCA17D";
      c4 =
        if stylixEnabled
        then colors.base02 # lighter gray
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
        style = "bg:${c4} fg:${fgAccent}";
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
          style = "bg:${c4} fg:${fgAccent}";
          format = "[ $symbol ]($style)";
        };
      }
      // builtins.mapAttrs makeLanguageConfig langSymbols;
  };
}

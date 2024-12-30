# See https://github.com/danth/stylix/issues/560
{
  config,
  lib,
  ...
}:
with lib; let
  hexDigitToInt = c: let
    hexChars = "0123456789abcdef";
  in
    stringLength (head (splitString c (toLower hexChars)));

  hexToRgb = hexColor: let
    r = substring 0 2 hexColor;
    g = substring 2 2 hexColor;
    b = substring 4 2 hexColor;
    toDecimal = hex: hexDigitToInt (substring 0 1 hex) * 16 + hexDigitToInt (substring 1 1 hex);
  in "${toString (toDecimal r)};${toString (toDecimal g)};${toString (toDecimal b)}";

  generateLsColors = colors: let
    mkColor = color: "38;2;${hexToRgb color}";
    colorMap = {
      # Special files and directories
      di = mkColor colors.base0D; # directory
      fi = mkColor colors.base05; # regular file
      ln = mkColor colors.base0C; # symbolic link
      ex = mkColor colors.base0A; # executable file
      bd = mkColor colors.base0E; # block device
      cd = mkColor colors.base0E; # character device
      so = mkColor colors.base0E; # socket
      pi = mkColor colors.base0E; # named pipe (FIFO)
      or = mkColor colors.base08; # orphaned symlink
      mi = mkColor colors.base08; # missing file
      su = mkColor colors.base0B; # file that is setuid (u+s)
      sg = mkColor colors.base0B; # file that is setgid (g+s)
      ca = mkColor colors.base0B; # file with capability
      tw = mkColor colors.base0A; # directory that is sticky and other-writable (+t,o+w)
      ow = mkColor colors.base0A; # directory that is other-writable (o+w) and not sticky
      st = mkColor colors.base0E; # directory with sticky bit set (+t) and not other-writable
      ee = mkColor colors.base05; # empty file (arrow for classifyAlt)
      no = mkColor colors.base05; # normal non-filename text
      rs = mkColor colors.base05; # reset to no color
      mh = mkColor colors.base05; # multi-hardlink
      lc = mkColor colors.base05; # left code (opening part of color sequence)
      rc = mkColor colors.base05; # right code (closing part of color sequence)
      ec = mkColor colors.base05; # end code (for non-filename text)
      # File extensions
      "*.bash" = mkColor colors.base0D;
      "*.bz2" = mkColor colors.base08;
      "*.c" = mkColor colors.base0D;
      "*.cfg" = mkColor colors.base05;
      "*.class" = mkColor colors.base0D;
      "*.conf" = mkColor colors.base05;
      "*.cpp" = mkColor colors.base0D;
      "*.cs" = mkColor colors.base0D;
      "*.css" = mkColor colors.base09;
      "*.deb" = mkColor colors.base08;
      "*.doc" = mkColor colors.base08;
      "*.docx" = mkColor colors.base08;
      "*.flac" = mkColor colors.base0C;
      "*.gif" = mkColor colors.base0D;
      "*.go" = mkColor colors.base0D;
      "*.gz" = mkColor colors.base08;
      "*.h" = mkColor colors.base0D;
      "*.html" = mkColor colors.base09;
      "*.ini" = mkColor colors.base05;
      "*.java" = mkColor colors.base0D;
      "*.jpeg" = mkColor colors.base0D;
      "*.jpg" = mkColor colors.base0D;
      "*.js" = mkColor colors.base0D;
      "*.json" = mkColor colors.base05;
      "*.less" = mkColor colors.base09;
      "*.lua" = mkColor colors.base0D;
      "*.md" = mkColor colors.base05;
      "*.mp3" = mkColor colors.base0C;
      "*.mp4" = mkColor colors.base0C;
      "*.nix" = mkColor colors.base0D;
      "*.odt" = mkColor colors.base08;
      "*.ogg" = mkColor colors.base0C;
      "*.pdf" = mkColor colors.base08;
      "*.png" = mkColor colors.base0D;
      "*.py" = mkColor colors.base0D;
      "*.rb" = mkColor colors.base0D;
      "*.rpm" = mkColor colors.base08;
      "*.rs" = mkColor colors.base0D;
      "*.scss" = mkColor colors.base09;
      "*.sh" = mkColor colors.base0D;
      "*.sql" = mkColor colors.base09;
      "*.svg" = mkColor colors.base0D;
      "*.tar" = mkColor colors.base08;
      "*.tgz" = mkColor colors.base08;
      "*.ts" = mkColor colors.base0D;
      "*.txt" = mkColor colors.base05;
      "*.vim" = mkColor colors.base0D;
      "*.wav" = mkColor colors.base0C;
      "*.xml" = mkColor colors.base05;
      "*.yaml" = mkColor colors.base05;
      "*.yml" = mkColor colors.base05;
      "*.zip" = mkColor colors.base08;
      "*.zsh" = mkColor colors.base0D;
    };
  in
    concatStringsSep ":" (mapAttrsToList (k: v: "${k}=${v}") colorMap);
in {
  programs.nushell.environmentVariables = {
    LS_COLORS = ''"${generateLsColors config.lib.stylix.colors}"'';
  };
}

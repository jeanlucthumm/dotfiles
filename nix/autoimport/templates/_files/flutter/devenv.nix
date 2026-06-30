{
  pkgs,
  lib,
  ...
}: {
  packages = with pkgs; [
  ];

  # Version strings reference: https://github.com/flutter/flutter/blob/main/packages/flutter_tools/lib/src/android/gradle_utils.dart
  android = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    flutter.enable = true;

    buildTools.version = ["34.0.0"];
    platforms.version = ["31" "33" "34" "35"];
    platformTools.version = "34.0.5";

    ndk = {
      enable = true;
      version = ["26.3.11579264" "27.0.12077973"];
    };
  };

  git-hooks.hooks = {
    dart-format = {
      enable = true;
      name = "Format Dart code";
      entry = "dart format";
      files = "\\.dart$";
      language = "system";
    };
  };
}
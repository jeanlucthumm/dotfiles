# TODO: this doesn't currently work
{
  config,
  lib,
  # Full system config passed in by HM when embedded
  osConfig ? {},
  ...
}: {
  programs.nushell.extraEnv = let
    darwinPathStr =
      if (osConfig ? environment && osConfig.environment ? systemPath)
      then osConfig.environment.systemPath
      else "";
    darwinPathList = lib.filter (p: p != "") (lib.splitString ":" darwinPathStr);
    # Expand $HOME/$USER placeholders to concrete paths.
    expanded = builtins.map (p: builtins.replaceStrings ["$HOME" "$USER"] [config.home.homeDirectory config.home.username] p) darwinPathList;
    final =
      lib.unique
      ([
          (config.home.homeDirectory + "/Library/Application Support/carapace/bin")
          "/opt/homebrew/bin"
        ]
        ++ expanded);
  in ''
    $env.PATH = ${builtins.toJSON final}
  '';
}

# Set up environment for nushell on Darwin
#
# Nushell doesn't source POSIX shell scripts, so it misses the nix-darwin
# environment setup from /etc/bashrc -> set-environment. This module
# replicates that setup in nushell's env.nu using osConfig as source of truth.
#
# This is the nushell equivalent of fish-fix.nix.
{
  config,
  lib,
  osConfig,
  ...
}: let
  homeDir = config.home.homeDirectory;
  user = config.home.username;

  # Get environment from nix-darwin config (source of truth for set-environment)
  darwinEnv = osConfig.environment.variables;
  darwinPath = osConfig.environment.systemPath;

  # Expand $HOME and $USER placeholders to concrete values
  expandVars = str:
    builtins.replaceStrings ["$HOME" "$USER"] [homeDir user] str;

  # Parse colon-separated path string into list and expand variables
  parsePath = pathStr:
    map expandVars (lib.filter (p: p != "") (lib.splitString ":" pathStr));

  # Extra paths to prepend (not in nix-darwin config)
  extraPaths = [
    "${homeDir}/Library/Application Support/carapace/bin"
    "/opt/homebrew/bin"
    "${homeDir}/.pub-cache/bin"
  ];

  # Final PATH: extras first, then nix-darwin paths
  pathEntries = extraPaths ++ (parsePath darwinPath);

  # Helper to format as nushell list
  toNuList = paths: lib.concatMapStringsSep "\n    " (p: ''"${p}"'') paths;
in {
  # Use macOS-native config location (nushell doesn't respect XDG on macOS)
  programs.nushell.configDir = "${homeDir}/Library/Application Support/nushell";

  programs.nushell.extraEnv = ''
    # Nix-darwin environment setup (replaces set-environment for nushell)
    # Source of truth: osConfig.environment.{systemPath,variables}

    $env.PATH = [
        ${toNuList pathEntries}
    ]

    # Environment variables from nix-darwin
    $env.NIX_SSL_CERT_FILE = "${darwinEnv.NIX_SSL_CERT_FILE}"
    $env.NIX_PATH = "${darwinEnv.NIX_PATH}"
    $env.TERMINFO_DIRS = "${expandVars darwinEnv.TERMINFO_DIRS}"
    $env.XDG_DATA_DIRS = "${expandVars darwinEnv.XDG_DATA_DIRS}"
    $env.XDG_CONFIG_DIRS = "${expandVars darwinEnv.XDG_CONFIG_DIRS}"
  '';
}

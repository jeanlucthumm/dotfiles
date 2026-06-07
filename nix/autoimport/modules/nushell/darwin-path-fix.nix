# Path / env fixes: nushell doesn't source POSIX shell scripts, so it
#   misses nix-darwin's set-environment. We replicate that setup in env.nu
#   using osConfig as source of truth (the nushell equivalent of fish-fix).
fp @ {jlib, ...}: {
  flake.modules.homeManager.base = {
    config,
    pkgs,
    lib,
    osConfig,
    ...
  }:
    jlib.mkHomeManager pkgs {
      darwin = let
        homeDir = config.home.homeDirectory;
        user = config.home.username;

        darwinEnv = osConfig.environment.variables;
        darwinPath = osConfig.environment.systemPath;

        expandVars = str:
          builtins.replaceStrings ["$HOME" "$USER"] [homeDir user] str;

        parsePath = pathStr:
          map expandVars (lib.filter (p: p != "") (lib.splitString ":" pathStr));

        # Extra paths to prepend (not in nix-darwin config)
        extraPaths = [
          "${homeDir}/Library/Application Support/carapace/bin"
          "/opt/homebrew/bin"
          "${homeDir}/.pub-cache/bin"
        ];

        pathEntries = extraPaths ++ (parsePath darwinPath);

        toNuList = paths: lib.concatMapStringsSep "\n    " (p: ''"${p}"'') paths;
      in {
        programs.nushell = {
          # macOS-native config location (nushell doesn't respect XDG on macOS)
          configDir = "${homeDir}/Library/Application Support/nushell";

          extraEnv = ''
            # Nix-darwin environment setup (replaces set-environment for nushell)
            # Source of truth: osConfig.environment.{systemPath,variables}

            $env.PATH = [
                ${toNuList pathEntries}
            ]

            # Uses `or ""` and `? NIX_PATH` guards for compatibility with
            # Determinate Nix, which doesn't set all the same variables as stock Nix.
            $env.NIX_SSL_CERT_FILE = "${darwinEnv.NIX_SSL_CERT_FILE or ""}"
            ${lib.optionalString (darwinEnv ? NIX_PATH) ''$env.NIX_PATH = "${darwinEnv.NIX_PATH}"''}
            $env.TERMINFO_DIRS = "${expandVars (darwinEnv.TERMINFO_DIRS or "")}"
            $env.XDG_DATA_DIRS = "${expandVars (darwinEnv.XDG_DATA_DIRS or "")}"
            $env.XDG_CONFIG_DIRS = "${expandVars (darwinEnv.XDG_CONFIG_DIRS or "")}"
          '';
        };
      };
    };
}

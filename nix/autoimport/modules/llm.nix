# LLM / AI tooling
fp @ {
  jlib,
  withSystem,
  ...
}: {
  flake.modules.homeManager.dev = let
    mkFpkgs = system: withSystem system ({config, ...}: config.packages);
  in
    jlib.mkHomeManager {
      generic = {
        pkgs,
        lib,
        system,
        ...
      }: {
        home.packages = [
          # Way more up to date than nixpkgs. signStable: when run outside a
          # terminal (launchd), macOS folder grants key on claude itself.
          (pkgs.signStable fp.inputs.claude-code.packages.${system}.claude-code)

          # `pnpm dlx` for npm-published MCP servers (e.g. firefox-devtools-mcp).
          # nodejs is needed alongside it: the servers' bin scripts shebang on
          # `env node`, and nixpkgs' pnpm keeps its own node private.
          pkgs.nodejs
          pkgs.pnpm
        ];
      };

      darwin = {
        pkgs,
        system,
        ...
      }: {
        home.packages = let
          tb = fp.inputs.terminal-browser.packages.${system}.default;
        in [
          # Wrapped so every caller (nushell, agents, scripts) gets the palette
          # off cmd+p, which kitty owns. The flag must trail the args, and
          # `action` rejects unknown flags, so only browser launches get it.
          (pkgs.writeShellScriptBin "terminal-browser" ''
            case "$1" in
              action | ls | setup | help)
                exec ${tb}/bin/terminal-browser "$@"
                ;;
              *)
                exec ${tb}/bin/terminal-browser "$@" --palette-key=ctrl+p
                ;;
            esac
          '')
        ];
      };

      nixos = {
        lib,
        pkgs,
        system,
        ...
      }: let
        fpkgs = mkFpkgs system;
      in {
        home.packages = [
          fpkgs.reddit-mcp-server
        ];

        programs = {
          codex.enable = true;
        };
      };
    };
}

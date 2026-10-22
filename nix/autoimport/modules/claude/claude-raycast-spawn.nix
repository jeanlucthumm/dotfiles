# Builder for Raycast script commands that start a background Claude Code
# agent in a fixed repo from anywhere on the Mac: type the prompt into Raycast
# and go. It is the comms-spawn skill's `claude --bg -n <name> "<prompt>"`
# with the cwd baked in.
#
# Exposed as the `claudeRaycastSpawn` module argument, not an option: a
# consumer writes the script straight into Raycast's scripts directory,
#
#   home.file.".local/share/raycast/scripts/claude-spawn-foo.sh".source =
#     claudeRaycastSpawn { name = "foo"; dir = "/abs/path/to/foo"; };
#
# and that directory is added once by hand under Raycast > Extensions >
# Script Commands. Raycast re-reads it on changes.
#
# Raycast runs scripts with a bare environment and no shell init, so the
# script rebuilds a login-shell PATH (the agent's hooks and tools live in the
# per-user profile) and enters the repo through `direnv exec`, so the agent's
# Bash calls and MCP servers see the project devshell exactly as they would
# from a terminal. The script's own helpers are absolute store paths so the
# agent's PATH stays what a shell would have, nothing more.
{jlib, ...}: {
  flake.modules.homeManager.agents = jlib.mkHomeManager {
    darwin = {
      config,
      lib,
      pkgs,
      ...
    }: let
      claude = "${config.jl.claude.package}/bin/claude";
      direnv = "${config.programs.direnv.package}/bin/direnv";
      coreutils = "${pkgs.coreutils}/bin";
      sed = "${pkgs.gnused}/bin/sed";

      # What a login shell on nix-darwin has, in the same order.
      agentPath = lib.concatStringsSep ":" [
        "${config.home.profileDirectory}/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
        "/opt/homebrew/bin"
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
      ];
    in {
      _module.args.claudeRaycastSpawn = {
        name,
        dir,
      }:
        pkgs.writeShellScript "claude-spawn-${name}" ''
          # @raycast.schemaVersion 1
          # @raycast.title Spawn agent in ${name}
          # @raycast.mode silent
          # @raycast.packageName Claude Code
          # @raycast.icon 🤖
          # @raycast.argument1 { "type": "text", "placeholder": "prompt" }
          # @raycast.argument2 { "type": "text", "placeholder": "name (optional)", "optional": true }
          # @raycast.description Start a background Claude Code agent in ${dir}.

          set -euo pipefail

          export PATH="${agentPath}"

          prompt=$1
          # Agent name defaults to the prompt's first four words as a slug.
          name=''${2:-}
          if [ -z "$name" ]; then
            name=$(printf '%s' "$prompt" \
              | ${coreutils}/tr '[:upper:]' '[:lower:]' \
              | ${coreutils}/tr -cs 'a-z0-9' '-' \
              | ${sed} 's/^-//; s/-$//' \
              | ${coreutils}/cut -d- -f1-4)
            name=''${name:-raycast-agent}
          fi

          # direnv logs to stderr, which Raycast only surfaces on failure, so
          # the HUD (last stdout line) stays clean.
          cd "${dir}"
          out=$(${direnv} exec "${dir}" ${claude} --bg -n "$name" "$prompt")

          # First line is "backgrounded · <id> · <name>", with colour codes.
          id=$(printf '%s\n' "$out" \
            | ${coreutils}/head -n1 \
            | ${sed} 's/\x1b\[[0-9;]*m//g' \
            | ${coreutils}/cut -d' ' -f3)
          echo "Spawned $name · $id"
        '';
    };
  };
}

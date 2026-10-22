# Declarative baseline for Claude Code's user settings (~/.claude/settings.json).
#
# The file must stay runtime-mutable: Claude Code appends "always allow"
# permission grants and rewrites preference keys as you use it. That churn is
# also why the file is not yadm-tracked (it diverged on every host), and why it
# cannot be a read-only store symlink. Upstream's programs.claude-code does
# exactly that symlink (no mutability option), so never enable it alongside
# this module. Instead an activation script deep-merges the declared attrset
# into whatever is on disk, the same shape HM itself uses for other
# self-mutating configs (see zed-editor's impureConfigMerger; the array union
# below is the one part with no upstream precedent):
#
#   - declared keys overwrite on-disk values, so nix changes propagate;
#   - arrays are unioned, so grants Claude Code appended survive a switch;
#   - undeclared keys are left alone entirely.
#
# Deliberately NOT declared, so each host keeps its own value:
#   model, theme            -- /model and /config choices should stick
#   feedbackSurveyState     -- pure runtime state
#   enabledPlugins extras   -- e.g. datadog on the work machine (object merge
#                              preserves them; only declared plugin keys are
#                              asserted)
#
# Array-element gotcha: the union compares whole elements, so *editing* a
# declared array entry (a hook object, an allow rule) leaves the old on-disk
# variant behind next to the new one until it is pruned from the file (for
# hook commands, by listing the old command in retiredHookCommands below).
# Keep declared entries byte-identical to what Claude Code has on disk -- the
# hook commands below are stable bin names for exactly this reason.
#
# Enforcement is switch-time only: a live session that rewrites the file wins
# until the next switch reasserts the baseline. Removing a key from the
# baseline stops asserting it but does not delete it from disk. The one
# removal path is retiredHookCommands: hook entries running one of those
# commands are dropped before the merge.
fp: {
  flake.modules.homeManager.agents = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.jl.claude;
    settingsFormat = pkgs.formats.json {};
    declared = settingsFormat.generate "claude-settings-declared.json" cfg.settings;
    jq = "${pkgs.jq}/bin/jq";

    # SessionStart hook: load the project's devenv into the session so every
    # Bash call runs inside it, the way `use devenv` does for direnv. Claude
    # Code sources whatever the hook appends to $CLAUDE_ENV_FILE before each
    # command. Installed as a bin so the hook command stays a stable name (a
    # store path would leave a stale duplicate behind on every edit; see the
    # array-element gotcha above).
    devenvHook = pkgs.writeShellScriptBin "claude-devenv-env" ''
      set -euo pipefail
      [ -n "''${CLAUDE_ENV_FILE:-}" ] || exit 0
      cd "$(${jq} -r .cwd)"
      [ -f devenv.nix ] || exit 0
      ${pkgs.devenv}/bin/devenv print-dev-env >>"$CLAUDE_ENV_FILE"
      # print-dev-env replaces PATH wholesale; keep the session's tools
      # reachable behind the project's, as nix develop does.
      printf 'export PATH="$PATH:%s"\n' "$PATH" >>"$CLAUDE_ENV_FILE"
    '';

    # jj-fetch / jj-push: `jj git fetch` and `jj git push -b X` without
    # spelling the token `git`, which Claude Code's worktree-isolation guard
    # refuses inside jj workspaces. Workspaces share one repo store, so a fetch
    # or push from any of them is the right operation. jj-push takes only a
    # bookmark name, never arbitrary flags.
    jjFetch = pkgs.writeShellScriptBin "jj-fetch" ''
      set -eu
      if [ "$#" -ne 0 ]; then
        echo "usage: jj-fetch   (no arguments)" >&2
        exit 2
      fi
      exec jj git fetch
    '';
    jjPush = pkgs.writeShellScriptBin "jj-push" ''
      set -eu
      if [ "$#" -ne 1 ] || [ -z "$1" ]; then
        echo "usage: jj-push <bookmark>" >&2
        exit 2
      fi
      case "$1" in
        -*) echo "jj-push: bookmark name must not start with '-'" >&2; exit 2 ;;
      esac
      exec jj git push -b "$1"
    '';

    # PreToolUse hook: rewrites `jj git fetch` / `jj git push -b X` onto the
    # jj-fetch / jj-push wrappers above when inside a Claude Code jj workspace.
    # Installed as a bin for the same stable-name reason as devenvHook.
    jjGitRewriteHook = pkgs.writeShellScriptBin "claude-jj-git-rewrite" ''
      # Runs on every Bash call; only pay for Python when the command text
      # could possibly match (the script re-checks precisely).
      input=$(cat)
      case $input in
        *jj*git*) printf '%s' "$input" | ${pkgs.python3}/bin/python3 ${./_jj-git-rewrite.py} \
          ${jjFetch}/bin/jj-fetch ${jjPush}/bin/jj-push ;;
      esac
    '';

    # WorktreeCreate / WorktreeRemove: EnterWorktree and isolated subagents get
    # jj workspaces instead of plain git worktrees (see _worktree-create.sh).
    # Built against the same jj and git the user runs, so a jj upgrade and the
    # hooks always ship in the same generation, and the create hook's build
    # runs both hooks against a scratch repo: a jj behavior change fails the
    # switch instead of the next subagent spawn.
    worktreeHookInputs = [
      config.programs.jujutsu.package
      config.programs.git.package
      pkgs.jq
      pkgs.coreutils
    ];
    worktreeRemoveHook = pkgs.writeShellApplication {
      name = "claude-worktree-remove";
      runtimeInputs = worktreeHookInputs;
      text = builtins.readFile ./_worktree-remove.sh;
    };
    worktreeCreateHook = pkgs.writeShellApplication {
      name = "claude-worktree-create";
      runtimeInputs = worktreeHookInputs;
      text = builtins.readFile ./_worktree-create.sh;
      derivationArgs.postCheck = ''
        export HOME="$TMPDIR/home" JJ_CONFIG="$TMPDIR/jj.toml"
        export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
        export PATH="${lib.makeBinPath worktreeHookInputs}:$PATH"
        mkdir -p "$HOME"
        printf '[user]\nname = "test"\nemail = "test@localhost"\n' >"$JJ_CONFIG"
        fail() { echo "worktree hook smoke test: $*" >&2; exit 1; }

        repo=$(realpath "$TMPDIR")/repo
        jj git init --colocate "$repo"
        echo hi >"$repo/file"
        jj -R "$repo" commit -m init
        jj -R "$repo" bookmark create main -r @-
        mkdir "$repo/sub"

        # From a subdirectory: the workspace must land at the repo root.
        wt=$(printf '{"cwd":"%s","name":"t","base_ref":"main"}' "$repo/sub" | "$target")
        [ "$wt" = "$repo/.claude/worktrees/t" ] || fail "unexpected path $wt"
        [ -f "$wt/.git" ] || fail "no linked git worktree"
        [ "$(realpath "$(git -C "$wt" rev-parse --show-toplevel)")" = "$wt" ] \
          || fail "git toplevel is not the workspace"
        [ "$(git -C "$wt" rev-parse HEAD)" = "$(jj -R "$repo" log --no-graph -r main -T commit_id)" ] \
          || fail "git HEAD is not the base"
        [ -z "$(git -C "$wt" status --porcelain --untracked-files=normal)" ] \
          || fail "fresh workspace is dirty"

        printf '{"worktree_path":"%s"}' "$wt" | ${worktreeRemoveHook}/bin/claude-worktree-remove
        [ ! -e "$wt" ] || fail "workspace dir left behind"
        [ -z "$(ls -A "$repo/.git/worktrees" 2>/dev/null)" ] || fail "git worktree metadata left behind"
        if jj -R "$repo" workspace list | grep '^t:' >/dev/null; then
          fail "jj workspace not forgotten"
        fi
      '';
    };
    # Hook commands from before the hooks moved into nix (the scripts lived
    # yadm-tracked in ~/.claude/hooks); pruned from settings.json on switch.
    retiredHookCommands = [
      "${config.home.homeDirectory}/.claude/hooks/worktree-create.sh"
      "${config.home.homeDirectory}/.claude/hooks/worktree-remove.sh"
    ];

    # Deep merge with the declared side winning. jq's builtin `*` would replace
    # arrays wholesale, which drops runtime permission grants; this unions them
    # instead. `$b == null` means the key only exists on disk: keep it.
    #
    # The params MUST be value-bound ($a; $b): plain jq params are call-by-name
    # filters, and re-evaluating the top-level `.` argument inside reduce
    # (where `.` is the accumulator) would silently drop the on-disk side.
    mergeFilter = pkgs.writeText "claude-settings-merge.jq" ''
      def deepmerge($a; $b):
        if ($a | type) == "object" and ($b | type) == "object" then
          reduce (($a + $b) | keys_unsorted[]) as $k
            ({}; .[$k] = deepmerge($a[$k]; $b[$k]))
        elif ($a | type) == "array" and ($b | type) == "array" then
          ($a + $b) | unique
        elif $b == null then $a
        else $b
        end;
      # Drop every on-disk hook group that runs a retired command.
      def prunehooks($retired):
        if (.hooks | type) == "object" then
          .hooks |= map_values(
            if type == "array"
            then map(select([.hooks[]?.command | select(IN($retired[]))] | length == 0))
            else .
            end)
        else .
        end;
      prunehooks($retired) | deepmerge(.; $declared[0])
    '';
  in {
    options.jl.claude.package = lib.mkOption {
      type = lib.types.package;
      # Way more up to date than nixpkgs. signStable: when run outside a
      # terminal (launchd), macOS folder grants key on claude itself.
      default = pkgs.signStable fp.inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
      description = "The Claude Code package to install and run.";
    };

    options.jl.claude.settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = {};
      description = ''
        Settings asserted into ~/.claude/settings.json at activation time.
        Definitions from all modules merge (lists concatenate), so hosts and
        the private repo can add their own keys on top of the baseline below.
      '';
    };

    config = {
      home.packages = [
        cfg.package
        devenvHook
        jjFetch
        jjPush
        jjGitRewriteHook
        worktreeCreateHook
        worktreeRemoveHook
      ];

      jl.claude.settings = {
        "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        fileSuggestion = {
          type = "command";
          command = "python3 ~/.claude/hooks/hook_file_suggestion.py";
        };
        statusLine = {
          type = "command";
          command = "bash ~/.claude/statusline-command.sh";
        };
        includeCoAuthoredBy = false;
        effortLevel = "high";
        skipDangerousModePermissionPrompt = true;
        skipWorkflowUsageWarning = true;
        fileCheckpointingEnabled = false;
        idleCompaction = false;
        spinnerTipsEnabled = false;
        voiceEnabled = true;
        preferredNotifChannel = "kitty";
        tui = "fullscreen";

        hooks = {
          WorktreeCreate = [
            {
              hooks = [
                {
                  type = "command";
                  command = "claude-worktree-create";
                }
              ];
            }
          ];
          SessionStart = [
            {
              hooks = [
                {
                  type = "command";
                  command = "claude-devenv-env";
                  # First run may build the env.
                  timeout = 600;
                }
              ];
            }
          ];
          PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "claude-jj-git-rewrite";
                  timeout = 10;
                }
              ];
            }
          ];
          WorktreeRemove = [
            {
              hooks = [
                {
                  type = "command";
                  command = "claude-worktree-remove";
                  timeout = 600;
                }
              ];
            }
          ];
        };

        extraKnownMarketplaces.home-assistant-skills.source = {
          source = "github";
          repo = "homeassistant-ai/skills";
        };
        enabledPlugins."home-assistant-skills@home-assistant-skills" = false;

        permissions = {
          # Classifier-backed auto mode; only honoured in user-level settings.
          defaultMode = "auto";
          # Read-only baseline. Host-specific grants Claude Code appends at
          # runtime are unioned in, not overwritten.
          allow = [
            "Bash(git status)"
            "Bash(git diff:*)"
            "Bash(git log:*)"
            "Bash(git show:*)"
            "Bash(git add:*)"
            "Bash(git commit:*)"
            "Bash(git fetch:*)"
            "Bash(git branch:*)"
            "Bash(git remote:*)"
            "Bash(git ls-tree:*)"
            "Bash(git merge-base:*)"
            "Bash(git rev-list:*)"
            "Bash(git tag:*)"
            "Bash(gh issue list:*)"
            "Bash(gh issue view:*)"
            "Bash(gh issue status:*)"
            "Bash(gh pr list:*)"
            "Bash(gh pr view:*)"
            "Bash(gh pr diff:*)"
            "Bash(gh pr checks:*)"
            "Bash(gh pr status:*)"
            "Bash(gh repo view:*)"
            "Bash(gh repo list:*)"
            "Bash(gh repo clone:*)"
            "Bash(gh release list:*)"
            "Bash(gh release view:*)"
            "Bash(gh search:*)"
            "Bash(gh status:*)"
            "Bash(gh browse:*)"
            "Bash(grep:*)"
            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(wc:*)"
            "Bash(file:*)"
            "Bash(tree:*)"
            "Bash(du:*)"
            "Fetch"
            "WebSearch"
            "WebFetch(domain:github.com)"
          ];
        };
      };

      home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        target="$HOME/.claude/settings.json"
        if [ -s "$target" ] && ! ${jq} empty "$target" 2>/dev/null; then
          # Never merge over a file we cannot parse; Claude Code may still be
          # able to recover state from it. Warn instead of failing activation.
          echo "claude-code: WARNING: $target is not valid JSON; skipping settings merge" >&2
        else
          if [ -s "$target" ]; then
            current=$(cat "$target")
          else
            current='{}'
          fi
          merged=$(printf '%s\n' "$current" \
            | ${jq} --slurpfile declared ${declared} \
              --argjson retired ${lib.escapeShellArg (builtins.toJSON retiredHookCommands)} \
              -f ${mergeFilter})
          if [ "$(printf '%s\n' "$current" | ${jq} -cS .)" \
            != "$(printf '%s\n' "$merged" | ${jq} -cS .)" ]; then
            verboseEcho "claude-code: asserting declared settings into $target"
            run mkdir -p "$HOME/.claude"
            claudeTmp=$(mktemp)
            printf '%s\n' "$merged" >"$claudeTmp"
            run mv "$claudeTmp" "$target"
          fi
        fi
      '';
    };
  };
}

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
#   hooks                   -- worktree hooks reference host-local scripts
#   feedbackSurveyState     -- pure runtime state
#   enabledPlugins extras   -- e.g. datadog on the work machine (object merge
#                              preserves them; only declared plugin keys are
#                              asserted)
#
# Enforcement is switch-time only: a live session that rewrites the file wins
# until the next switch reasserts the baseline. Removing a key from the
# baseline stops asserting it but does not delete it from disk; if removal is
# ever needed, add a prune list that runs jq del() before the merge.
_: {
  flake.modules.homeManager.dev = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.jl.claude;
    settingsFormat = pkgs.formats.json {};
    declared = settingsFormat.generate "claude-settings-declared.json" cfg.settings;
    jq = "${pkgs.jq}/bin/jq";

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
      deepmerge(.; $declared[0])
    '';
  in {
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
        spinnerTipsEnabled = false;
        voiceEnabled = true;
        preferredNotifChannel = "kitty";
        tui = "fullscreen";

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
            | ${jq} --slurpfile declared ${declared} -f ${mergeFilter})
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

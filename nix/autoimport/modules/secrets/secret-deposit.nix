# Manual hardware-key-gated deposit of decrypted secrets to remote (keyless) hosts.
#
# Headless servers boot unattended and cannot perform a YubiKey PIN+touch, so
# they cannot be agenix recipients. Instead, a secret is decrypted here behind
# the hardware key, then pushed over SSH to the destination. The decryption
# authority never lives on the remote box. Run manually from the CLI -- SSH auth
# uses the FIDO2 key, so every run requires a touch.
#
# Contributes to the merged `homeManager.secrets` module, so any hardware-key
# host gets the option set; the `deposit-secrets` tool only lands on PATH when
# `jl.secretDeposit.enable` is set.
_: {
  flake.modules.homeManager.secrets = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.jl.secretDeposit;

    # One `deposit` call per target. Every argument is shell-escaped except
    # `source`, which is injected raw so the shell expands runtime vars in
    # agenix paths (e.g. $XDG_RUNTIME_DIR), matching the get-key-* scripts. It
    # goes last so that if it ever does word-split, the extra words land past
    # the end of the argument list instead of shifting the escaped ones.
    depositCall = name: t: let
      quoted = lib.escapeShellArgs [
        name
        "${t.remoteUser}@${t.host}"
        t.path
        t.owner
        t.group
        t.mode
      ];
    in "deposit ${quoted} ${t.source}";

    depositCalls = lib.pipe cfg.targets [
      (lib.mapAttrsToList depositCall)
      lib.concatLines
    ];

    depositScript = pkgs.writeShellScriptBin "deposit-secrets" ''
      set -euo pipefail
      umask 077

      selected=("$@")
      should_run() {
        [ ''${#selected[@]} -eq 0 ] && return 0
        local n="$1" s
        for s in "''${selected[@]}"; do [ "$s" = "$n" ] && return 0; done
        return 1
      }

      # Argument order mirrors the generated calls below: the escaped args
      # first, then the unescaped source path last.
      deposit() {
        local name="$1" dest="$2" path="$3" owner="$4" group="$5" mode="$6" src="$7"
        should_run "$name" || return 0
        if [ ! -r "$src" ]; then
          echo "ERROR: $name: source '$src' not readable -- run 'delock' first?" >&2
          return 1
        fi
        echo "Depositing $name -> $dest:$path (owner=$owner:$group mode=$mode)"
        # install(1) on the remote (GNU coreutils) sets owner/group/mode and
        # creates parent dirs in one shot, reading plaintext from stdin.
        ${pkgs.openssh}/bin/ssh "$dest" \
          "install -D -m '$mode' -o '$owner' -g '$group' /dev/stdin '$path'" < "$src"
      }

      ${depositCalls}
      echo "All requested secrets deposited."
    '';
  in {
    options.jl.secretDeposit = {
      enable = lib.mkEnableOption "manual hardware-key-gated deposit of decrypted secrets to remote hosts";

      targets = lib.mkOption {
        description = ''
          Secrets to push from this hardware-key host to a remote (keyless) host.
          Each target is decrypted locally via agenix (run `delock` first on
          Darwin), then written over SSH to the destination. SSH auth uses the
          FIDO2 security key, so each run requires a touch.

          Invoke with `deposit-secrets` to push all targets, or
          `deposit-secrets <name>...` to push a subset.
        '';
        default = {};
        example = lib.literalExpression ''
          {
            claude-telegram = {
              source = config.age.secrets.claude-telegram.path;
              host = "server";
              path = "/var/lib/claude-agent/telegram.env";
              owner = "claude-agent";
              group = "claude-agent";
            };
          }
        '';
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              description = "Local path to the decrypted secret, e.g. config.age.secrets.<name>.path.";
            };
            host = lib.mkOption {
              type = lib.types.str;
              description = "SSH destination host, as resolvable from this machine.";
            };
            remoteUser = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = "SSH user on the destination. Needs rights to chown the deposited file.";
            };
            path = lib.mkOption {
              type = lib.types.str;
              description = "Absolute destination path on the remote host.";
            };
            owner = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = "Owner of the deposited file on the remote host.";
            };
            group = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = "Group of the deposited file on the remote host.";
            };
            mode = lib.mkOption {
              type = lib.types.str;
              default = "0400";
              description = "Permission bits of the deposited file.";
            };
          };
        });
      };
    };

    config.home.packages = lib.optional cfg.enable depositScript;
  };
}

# Durability for the Obsidian vault on server.
#
# The vault is Syncthing-shared and edited by phone, laptops and the claude
# rc agents. A local git repo turns that into a timeline: every minute a
# pass commits whatever is dirty ("changes from server on <date>"). Clean
# tree = no commit. `.git` is in the Syncthing ignore list, so the repo is
# server-local and never syncs out; backups.nix copies it to the ZFS pool
# nightly. git-sync (agent-memory.nix) isn't reused because it insists on a
# remote to push to.
{
  flake.modules.nixos.homeServer = {pkgs, ...}: let
    vault = "/home/jeanluc/obsidian/vault";
  in {
    systemd.services.vault-autocommit = {
      description = "Commit Obsidian vault changes if dirty";
      path = [pkgs.git];
      serviceConfig = {
        Type = "oneshot";
        User = "jeanluc";
        Group = "users";
        WorkingDirectory = vault;
      };
      script = ''
        if [ ! -e .git ]; then
          git init -q -b main
          git config user.name vault-autocommit
          git config user.email vault-autocommit@server.local
        fi
        git add -A
        if ! git diff --cached --quiet; then
          git commit -q -m "changes from $(uname -n) on $(date -Is)"
        fi
      '';
    };

    systemd.timers.vault-autocommit = {
      description = "Commit Obsidian vault changes every minute";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
      };
    };
  };
}

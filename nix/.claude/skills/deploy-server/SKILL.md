---
name: deploy-server
description: Deploy the server's NixOS config from the server itself, with deploy-rs rollback. Use when Jean-Luc asks to deploy the server / deploy to server.
disable-model-invocation: true
---

Deploys a pinned GitHub commit, never a working tree: merge or push first.
Not for building or checking a config, and not for other hosts.

```bash
rev=$(gh api repos/jeanlucthumm/dotfiles/commits/master --jq .sha)
deploy "github:jeanlucthumm/dotfiles/$rev?dir=nix#server"
```

Run it in background Bash and report the commit. `--dry-activate` first when
the change touches units or networking: prints what would restart, changes
nothing.

Exit 0 is activated and confirmed. Failure after "Success activating" means
the confirm hop failed and deploy-rs already rolled back; the output says why.
The hop is SSH to `server`, which resolves to the box itself, so it catches
sshd breaking, not the box dropping off the network.

---
name: deploy
description: Deploy the server (`deploy .#server`). Use when asked to deploy or redeploy the server, or to make a merged change take effect there.
---

- From a session on the server, run the deploy detached with `systemd-run --user` (pass `PATH` and `SSH_AUTH_SOCK`) from a clean checkout of `master@origin`: the deploy can restart the rc unit hosting your session, and deploy-rs rolls back if the deploying process dies before it confirms.

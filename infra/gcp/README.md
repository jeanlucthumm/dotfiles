# GCP for agents

The project `agent-sandbox-jeanlucthumm` is for general agent use. Agents act as the
`cloud-agents` service account, which is Owner of this project and nothing else.
Anything commercial gets its own project and a private repo, not this one.

| Root | Who runs it | Credentials | State |
| --- | --- | --- | --- |
| `bootstrap/` | Jean-Luc | his user account (`gcloud auth application-default login`) | committed `terraform.tfstate` |
| `sandbox/` | agents | `cloud-agents` key, via `GOOGLE_APPLICATION_CREDENTIALS` | `gs://agent-sandbox-jeanlucthumm-tfstate/sandbox` |

`bootstrap/` holds what agents must not change: the project, billing, the service
account and its role, the budget, and the sandbox state bucket. Never add
secret-bearing resources there (keys, API keys), since its state is public.

## Running

OpenTofu (`tofu`) is on the server's PATH. On a workstation, use
`nix run nixpkgs#opentofu -- <cmd>`.

```sh
cd infra/gcp/<root>
tofu init
tofu plan
tofu apply
```

After a bootstrap apply, commit `terraform.tfstate`.

## Server credentials

`nix/autoimport/modules/gcp-sandbox.nix` (server only) sets up gcloud and
OpenTofu and exports the credentials to every agent session. The key itself is a
plain file at `~/.config/gcloud-sandbox/key.json`.

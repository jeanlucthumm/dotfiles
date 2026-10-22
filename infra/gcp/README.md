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

`infra/gcp/devenv.nix` provides OpenTofu (`tofu`); direnv loads it on `cd`. It's also
on the server's PATH.

```sh
cd infra/gcp/<root>
tofu init
tofu plan
tofu apply
```

After a bootstrap apply, commit `terraform.tfstate`.

## Server credentials

`nix/autoimport/modules/gcp/gcp.nix` (server only) sets up gcloud and
OpenTofu and exports the credentials to every agent session. The key itself is a
plain file at `~/.config/gcloud-sandbox/key.json`.

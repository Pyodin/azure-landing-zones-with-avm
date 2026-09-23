# bootstrap

The one root applied by hand, because a pipeline cannot create the credential it signs
in with. Everything after it runs in Actions.

| Creates | For |
|---|---|
| Storage account, one container per landing zone | Remote state. A container is an RBAC boundary |
| A `backend.hcl` per landing zone | Local `plan`. Gitignored; CI passes the same values as flags |
| Two managed identities with federated credentials | What Actions authenticates as. `plan` reads, `apply` writes |

## Run it

Needs **Owner at the tenant root group**, to grant the CI identity the same, and
**Global Administrator**, to grant it `Application.ReadWrite.OwnedBy` on Graph.

```bash
az login
terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply
```

`subscription_id` in `locals.tf` decides where it lands.

## Then wire GitHub

Copy `github_variables` into **Actions variables**, at repository scope — an environment
scope hides them from the plan job. None is a secret: the federated credential is the
control.

| Variable | Is |
|---|---|
| `AZURE_PLAN_CLIENT_ID` | Reads |
| `AZURE_APPLY_CLIENT_ID` | Writes. Only a job in the `production` environment can obtain it |
| `AZURE_TENANT_ID` | The tenant |
| `TFSTATE_RESOURCE_GROUP` | Where state lives |
| `TFSTATE_STORAGE_ACCOUNT` | The state account |
| `TFSTATE_SUBSCRIPTION_ID` | Its subscription, not the one a landing zone deploys to |

Create a **`production` environment**, required reviewer yourself, deployment branches
`main` only. Then `Actions` → `deploy` → `Run workflow`.

## Notes

**No backend.** This root creates the account the others store state in. Its state stays
local and gitignored; losing it means importing a few resources, not rebuilding them.

**Identity is the only control on state.** Shared keys are disabled and the account
carries no network rules: a hosted runner has no address range worth allow-listing.
Locking it down means a private endpoint and a self-hosted runner.

**Adding a landing zone:** `landing_zones` here, then both matrices in
`.github/workflows/deploy.yml`.

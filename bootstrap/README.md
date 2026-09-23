# bootstrap

The one root applied by hand, and it exists so that it is the only one.

| Creates | For |
|---|---|
| A storage account, one container per landing zone | Remote state. A container is an RBAC boundary, so a team can be given its own state and nothing else |
| A `backend.hcl` in each landing zone directory | Local `plan`. Gitignored — CI passes the same values as `-backend-config=` flags |
| Two managed identities with federated credentials | What GitHub Actions authenticates as. No secret exists, so none can leak. `plan` reads, `apply` writes |

A pipeline cannot create the credential it signs in with. That is the whole reason this
step is manual; everything after it runs in Actions.

## Before you run it

Two roles, and both are needed for the identity, not for the storage:

- **Owner at the tenant root group** — to grant the CI identity the same, which
  `platform/management` needs to create management groups and assign roles.
- **Global Administrator** — to grant it `Application.ReadWrite.OwnedBy` on Microsoft
  Graph, which `platform/identity` needs to create an app registration. Granting any
  Graph application permission requires it.

## Run it

```bash
az login
terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply
```

`subscription_id` in `locals.tf` decides where this lands, and the same value is written
into every `backend.hcl` so a landing zone reaches the state account regardless of which
subscription it deploys into.

## Then wire GitHub

Copy the `github_variables` output into the repository's **Actions variables**. None of
them is a secret — with OIDC there is nothing to store, the federated credential is the
control:

| Variable | Is |
|---|---|
| `AZURE_PLAN_CLIENT_ID` | Reads. Pull requests and dispatched plans use it |
| `AZURE_APPLY_CLIENT_ID` | Writes. Only a job in the `production` environment can obtain it |
| `AZURE_TENANT_ID` | The tenant |
| `TFSTATE_RESOURCE_GROUP` | Where the state account lives |
| `TFSTATE_STORAGE_ACCOUNT` | The state account |
| `TFSTATE_SUBSCRIPTION_ID` | The subscription the state account lives in, which is not the one a landing zone deploys to |

Then create a **`production` environment**, set **Required reviewers** to yourself and
**Deployment branches** to `main` only. The environment gates the apply and is the
subject of the apply identity's only federated credential, so a job that does not declare
it cannot obtain a token that writes.

From there: `Actions` → `deploy` → `Run workflow`.

## Notes

**No backend, on purpose.** This root creates the account the others store state in, so
it cannot store its own state there. Its state stays local and gitignored. Losing it
costs nothing: everything here is idempotent, and the storage account outlives the file
describing it.

**Shared keys are disabled**, so Terraform reaches the blob data plane with Entra ID.
Whoever applies this is granted Storage Blob Data Owner on the account, as is the CI
identity. A production setup narrows both to Storage Blob Data Contributor on a single
container, per team.

**Adding a landing zone** means adding its path to `landing_zones` in `locals.tf` and
applying again — then adding it to the matrix in `.github/workflows/deploy.yml`.

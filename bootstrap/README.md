# bootstrap

Creates the storage account every landing zone keeps its state in, one container each,
and writes a `backend.hcl` into each landing zone directory.

This root has **no backend**. It creates the account the others store state in, so it
cannot store its own state there. Its state stays local and gitignored; losing it costs
nothing, because everything here is idempotent and the storage account outlives the file
that describes it.

```bash
az login
terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply
```

Then initialise each landing zone with the generated configuration:

```bash
terraform -chdir=landing-zones/platform/management init -backend-config=backend.hcl
```

Adding a landing zone means adding its path to `landing_zones` in `locals.tf` and
applying again.

Shared key access is disabled, so Terraform authenticates to the data plane with Entra
ID and whoever applies this is granted Storage Blob Data Owner. A production setup
narrows that to Storage Blob Data Contributor per container, scoped to the team that
owns the landing zone.

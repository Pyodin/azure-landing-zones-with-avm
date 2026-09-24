# Landing zones

One Terraform root per directory, one state each. No root reads another root's state:
what crosses a boundary is copied into the consuming root's `locals.tf`.

Apply in this order. Each prints the values the next needs.

| Order | Landing zone | Owns |
|---|---|---|
| 1 | `platform/identity` | Entra ID objects |
| 2 | `platform/connectivity` | Hub network; optional firewall, VPN, Bastion and private DNS zones |
| 3 | `platform/management` | Management groups, ALZ policy, Log Analytics |
| 4 | `platform/subscriptions` | Budgets; application landing zones' management group, spoke network and hub peering |

With private DNS on, connectivity comes before management: the private DNS policy is
granted a role on each zone, so the zones must exist first.

Every root keeps the same file names:

- `locals.tf` is the entire configuration. No variables, no `.tfvars`.
- `terraform.tf` pins versions and points at the backend the `bootstrap` root created.

Address ranges in use: [ip-plan.md](ip-plan.md). See the repository [README](../README.md)
for the architecture and the deployment walkthrough.

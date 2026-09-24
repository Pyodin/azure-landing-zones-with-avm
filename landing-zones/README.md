# Landing zones

One Terraform root per directory, one state each. No root reads another root's state:
what crosses a boundary is copied into the consuming root's `locals.tf`.

Apply in this order. Each prints the values the next needs.

| Order | Landing zone | Owns |
|---|---|---|
| 1 | `platform/identity` | Entra ID objects |
| 2 | `platform/connectivity` | Hub network, private DNS zones, optional firewall, VPN and Bastion |
| 3 | `platform/management` | Management groups, ALZ policy, Log Analytics |
| 4 | `platform/subscriptions` | Budgets on the platform subscriptions |

Connectivity comes before management: the private DNS policy is granted a role on each
zone, so the zones must exist first.

Every root keeps the same file names:

- `locals.tf` is the entire configuration. No variables, no `.tfvars`.
- `terraform.tf` pins versions and points at the backend the `bootstrap` root created.

See the repository [README](../README.md) for the architecture and the deployment walkthrough.

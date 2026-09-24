# Management: policy

Management groups and Azure Policy come from the official
[ALZ library](https://azure.github.io/Azure-Landing-Zones-Library/), deployed by
[`avm-ptn-alz`](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm/latest).
The library holds the policies; `lib/` and `alz.tf` adapt them.

## How it fits together

```
ALZ library (pinned in providers.tf)
  └─ lib/        what applies where: hierarchy and archetype overrides
       └─ alz.tf    values plugged in: workspace, DNS zones, subscriptions
            └─ Azure: management groups, definitions, assignments, role assignments
```

- **Architecture** (`lib/alz_custom.alz_architecture_definition.yaml`): the management
  group tree, and the archetype attached to each group.
- **Archetype**: a named set of policy assignments. `lib/*_custom.alz_archetype_override.yaml`
  take a library archetype and add or remove assignments.
- **Assignment**: one policy or initiative applied at a group. Every group and
  subscription below inherits it.

Assignments removed in `lib/` are the ones that bill per VM, per GB or per database:
VM monitoring, change tracking, backup, diagnostic settings, SQL Defender, DDoS.

## Effects

| Effect | Behaviour | Examples here |
|---|---|---|
| `Deny` | Refuses a non-compliant deployment | `Enforce-Allowed-Locs`, `Deny-Public-Endpoints`, `Enforce-GR-*` |
| `Audit` | Reports only, in the compliance view | `Audit-ZoneResiliency`, `Audit-UnusedResources` |
| `DeployIfNotExists` / `Modify` | Fixes resources as they are created or updated | `Deploy-Private-DNS-Zones`, `Deploy-AzActivity-Log` |

`DeployIfNotExists` does not touch existing resources until a
[remediation task](https://learn.microsoft.com/azure/governance/policy/how-to/remediate-resources)
is run. Terraform creates none.

See [effect basics](https://learn.microsoft.com/azure/governance/policy/concepts/effect-basics).

## Cost

Policy itself is free. What costs money is what a `DeployIfNotExists` assignment
deploys, and the data it sends to Log Analytics. Idle, with no VMs or databases, the only
cost is the workspace: ~€2.37/GB ingested, under the daily cap set in `locals.tf`.

Removed in `lib/`, with what they would cost:

| Assignment | Cost if kept |
|---|---|
| `Deploy-VM-Monitoring`, `-VMSS-`, `-vmHybr-` | Agent and VM Insights data, ~€15–40 per VM/month |
| `Deploy-*-ChangeTrack` | ~€3–10 per VM/month |
| `Deploy-VM-Backup` | New Recovery Services vault, ~€5 per VM/month plus storage |
| `Deploy-Diag-LogsCat` | Diagnostic logs on every resource, €30–150+/month once a firewall or AKS exists |
| `Deploy-MDFC-SqlAtp`, `-OssDb`, `-DefSQL-AMA`, `Deploy-SQL-Threat`, `Deploy-AzSqlDb-Auditing` | ~€15 per database server/month each, from the first database |
| `Enable-DDoS-VNET` | No direct cost, but it expects a DDoS plan (~€2,500/month) and breaks VNet deployments without one |

Kept and free or negligible: every `Deny`, `Audit` and `Enforce-GR-*` assignment,
activity logs (free ingestion), service health alerts, private DNS when enabled.

`Deploy-MDFC-Config-H224` is kept, with every Defender plan `Disabled`. The library
disables all but Defender for AI, which `alz.tf` disables. Any plan the assignment does
not set falls back to the initiative default, which enables it, and Defender plans bill
per resource: check new plans after a library upgrade.

Before applying a library upgrade, check the plan for new `Deploy-*` assignments.

## Expected plan warning

`External role assignment creation required` on `Deploy-MCSB2-Monitoring` is a
[known provider limitation](https://github.com/Azure/Azure-Landing-Zones/issues/1654). Both policies it
names run as `AuditIfNotExists` in that initiative, so they never deploy and need no
role. Left unsuppressed, so a real case after a library upgrade still shows.

## Common changes

| To | Do |
|---|---|
| Remove an assignment from a group | Add it to `policy_assignments_to_remove` in that group's override |
| Add a library assignment to a group | Add it to `policy_assignments_to_add` |
| Add your own assignment | Drop a `*.alz_policy_assignment.json` in `lib/` and add it to an override |
| Audit instead of deny | `policy_assignments_to_modify` → `enforcement_mode = "DoNotEnforce"` |
| Change a parameter | `policy_assignments_to_modify` → `parameters` |
| Set one value across assignments | `policy_default_values`, names from the library's and `lib/`'s `alz_policy_default_values.json` |
| Exclude a scope | `policy_assignments_to_modify` → `not_scopes` |
| Exempt one resource | A [policy exemption](https://learn.microsoft.com/azure/governance/policy/concepts/exemption-structure), not managed here |
| Upgrade the library | Bump `ref` in `providers.tf`, then read the plan |

`policy_assignments_to_modify` is keyed by the group that holds the assignment, then
the assignment name.

## Private DNS

`Deploy-Private-DNS-Zones` on `alz-corp` attaches every new private endpoint to the
matching zone in the connectivity subscription, so workloads need no write access to
the hub. Only the zones in `local.private_dns_zones` are wired, keyed by the policy's
parameter name. Empty, the assignment is not created.

To cover a service, uncomment or add its zone in connectivity's `private_dns_zones` and
apply it, then here. The policy identity is granted a role on each zone, so the zones
must exist first.

## Further reading

- [Azure Policy overview](https://learn.microsoft.com/azure/governance/policy/overview)
- [CAF governance design area](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/governance)
- [ALZ with Terraform](https://azure.github.io/Azure-Landing-Zones/terraform/)
- [ALZ library source](https://github.com/Azure/Azure-Landing-Zones-Library)
- [`alz` provider](https://registry.terraform.io/providers/Azure/alz/latest/docs)

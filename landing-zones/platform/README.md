# Platform landing zones

Shared services with a long life and few owners. A workload consumes them and never
changes them.

| Landing zone | Owns |
|---|---|
| `management` | Management group hierarchy and policy through [`avm-ptn-alz`](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm), free AMBA alerts, the shared Log Analytics workspace |
| `identity` | Entra ID application registrations. No `azurerm` provider: a directory object belongs to a tenant |
| `connectivity` | Hub through [`avm-ptn-alz-connectivity-hub-and-spoke-vnet`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm): private DNS zones, and behind flags a Basic firewall, a point-to-site VPN and a Developer Bastion |
| `subscriptions` | Monthly budgets through [`avm-ptn-alz-sub-vending`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure) |

Policy comes from the ALZ library, trimmed in `management/lib/`: the archetype
overrides there remove every assignment that bills per VM or per GB (VM Insights,
change tracking, backup, diagnostic settings, SQL Defender, DDoS).

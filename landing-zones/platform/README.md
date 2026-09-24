# Platform landing zones

Shared services with a long life and few owners. A workload consumes them and never
changes them.

| Landing zone | Owns |
|---|---|
| `management` | Management group hierarchy and policy through [`avm-ptn-alz`](https://registry.terraform.io/modules/Azure/avm-ptn-alz/azurerm), the shared Log Analytics workspace |
| `identity` | Entra ID application registrations. No `azurerm` provider: a directory object belongs to a tenant |
| `connectivity` | Hub through [`avm-ptn-alz-connectivity-hub-and-spoke-vnet`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm): a virtual network, and behind flags a Basic firewall, a point-to-site VPN, a Developer Bastion and private DNS zones. See [connectivity/README.md](connectivity/README.md) |
| `subscriptions` | Through [`avm-ptn-alz-sub-vending`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure): monthly budgets, and for application landing zones a management group, a spoke network and its hub peering |

Policy comes from the ALZ library, trimmed in `management/lib/`: the archetype
overrides there remove every assignment that bills per VM or per GB (VM Insights,
change tracking, backup, diagnostic settings, SQL Defender, DDoS).

See [management/README.md](management/README.md) for how the policy works and what it costs.

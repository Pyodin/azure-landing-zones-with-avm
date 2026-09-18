# Platform landing zones

Shared services with a long life and few owners. A workload consumes them and never
changes them.

| Landing zone | Owns |
|---|---|
| `management` | Management group hierarchy, the deny-only baseline, the private DNS initiative, the shared Log Analytics workspace |
| `identity` | Entra ID application registrations. No `azurerm` provider at all: a directory object belongs to a tenant, not to a subscription |
| `connectivity` | Hub virtual network, Azure Firewall with DNS proxy, private DNS zones, point-to-site VPN, optional Bastion |

Policy is assigned here, at a management group, and inherited by every subscription
placed beneath it. That is what makes a new landing zone compliant on the day its
subscription is created rather than the day someone remembers to configure it.

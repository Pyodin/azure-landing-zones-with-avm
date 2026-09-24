# Connectivity: hub network

The hub of the hub and spoke, deployed by
[`avm-ptn-alz-connectivity-hub-and-spoke-vnet`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest).
Everything but the virtual network is switched on in `locals.tf`, all off by default.

## What each switch deploys

| Switch | Deploys | Needs |
|---|---|---|
| none | Resource group and hub virtual network `10.0.0.0/16` | |
| `deploy_firewall` | Azure Firewall Basic, its policy, rule collections for spoke egress, a route table, two public IPs | `has_firewall = true` in spokes |
| `deploy_vpn` | Point-to-site VPN gateway with Entra ID sign-in | `platform/identity` applied, `has_vpn_gateway = true` in spokes |
| `deploy_bastion` | Bastion Developer and a Linux jumpbox in a management subnet | |
| `private_dns_zones`, one line per zone | A resource group and those zones, linked to the hub. Empty map: none | The same zones in `platform/management`'s `private_dns_zones` |

Notes:

- **Firewall Basic** caps at 250 Mbps and has no DNS proxy. Spokes resolve private
  endpoints through their own link to each private DNS zone.
- **Bastion Developer** reaches VMs in the hub only: it does not cross peerings.
- **VPN clients** do not resolve private endpoint names. That needs a DNS Private
  Resolver (~€155/month), left out.
- **Private DNS** comes with a policy in `platform/management` that registers every new
  private endpoint in the matching zone. The policy is granted a role on each zone, so
  apply connectivity before management when turning it on.

## Cost

France Central, retail pay-as-you-go, 730 hours a month. An order of magnitude, not a
quote.

| Component | Flag | EUR / month |
|---|---|---:|
| Virtual network, resource group, route table | always | 0 |
| Azure Firewall Basic | `deploy_firewall` | 248 + €0.056/GB |
| Firewall public IPs (data and management) | `deploy_firewall` | 6 |
| VPN gateway VpnGw1AZ and its public IP | `deploy_vpn` | 135 |
| Bastion Developer | `deploy_bastion` | 0 |
| Jumpbox Standard_B2ats_v2 and Standard SSD | `deploy_bastion` | ~9 |
| Private DNS zone, each | `private_dns_zones` | 0.43 |
| **Resting, all off** | | **0** |

The firewall and the gateway bill per hour deployed, used or not: turn them off when a
test is over. Virtual network peering bills per GB in both directions (~€0.01/GB).

Two module defaults would cost more than everything above combined and are set off in
`network.tf`: the DDoS Network Protection plan (~€2,500/month) and the DNS Private
Resolver (~€155/month). ExpressRoute, NAT gateway and the module's own Bastion are
off too.

## Further reading

- [Hub-spoke network topology](https://learn.microsoft.com/azure/architecture/networking/architecture/hub-spoke)
- [Azure Firewall SKUs](https://learn.microsoft.com/azure/firewall/choose-firewall-sku)
- [Point-to-site VPN with Entra ID](https://learn.microsoft.com/azure/vpn-gateway/point-to-site-entra-gateway)
- [Bastion Developer](https://learn.microsoft.com/azure/bastion/quickstart-developer)
- [Private endpoint DNS](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)

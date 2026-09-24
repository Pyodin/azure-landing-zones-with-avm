# IP address plan

Check here before taking a range, and add it in the same change. Nothing may overlap:
the hub, every spoke and the VPN clients share one routing domain. VPN clients must
also avoid the networks they connect from (home routers often use 192.168.0.0/16).

| Range | Used by | Set in |
|---|---|---|
| 10.0.0.0/16 | Hub | connectivity `hub_address_space` |
| 10.1.0.0/16 | Spoke `dev` | subscriptions `subscriptions.dev.spoke` |
| 172.20.0.0/24 | VPN clients | connectivity `vpn_client_address_space` |

Next spoke: the next free /16 (10.2.0.0/16). Also list it in connectivity
`spoke_address_spaces`.

## Hub subnets

| Range | Subnet |
|---|---|
| 10.0.0.0/26 | AzureFirewallSubnet |
| 10.0.0.64/26 | AzureFirewallManagementSubnet |
| 10.0.2.0/27 | GatewaySubnet |
| 10.0.3.0/27 | Management (jumpbox) |
| 10.0.4.0/28 | DNS forwarder |

## Spoke subnets

| Range | Spoke | Subnet |
|---|---|---|
| 10.1.0.0/24 | `dev` | Private endpoints |

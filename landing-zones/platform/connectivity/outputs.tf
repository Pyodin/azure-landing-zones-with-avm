output "resource_group_name" {
  description = "Connectivity resource group holding the hub network and firewall."
  value       = module.resource_group_connectivity.name
}

output "virtual_network_name" {
  description = "Hub virtual network name, consumed by spoke landing zones for peering."
  value       = module.hub_virtual_network.name
}

output "virtual_network_id" {
  description = "Hub virtual network resource ID."
  value       = module.hub_virtual_network.resource_id
}

output "firewall_name" {
  description = "Azure Firewall name."
  value       = module.firewall.resource.name
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP, used as the next hop and DNS server for spokes."
  value       = module.firewall.resource.ip_configuration[0].private_ip_address
}

output "private_dns_zone_resource_ids" {
  description = "Private DNS zones keyed by their module key."
  value       = module.private_dns_zones.private_dns_zone_resource_ids
}

# Mirrors the "hub" block in the application landing zone locals.
output "spoke_inputs" {
  description = "Values to copy into the application landing zone locals."
  value = {
    subscription_id         = data.azurerm_client_config.current.subscription_id
    resource_group_name     = module.resource_group_connectivity.name
    dns_resource_group_name = module.resource_group_dns.name
    virtual_network_name    = module.hub_virtual_network.name
    firewall_name           = module.firewall.resource.name
  }
}

output "vpn_gateway_name" {
  description = "Point-to-site VPN gateway name, empty when deploy_vpn is false."
  value       = local.deploy_vpn ? local.names.vpn_gateway : ""
}

output "vpn_client_address_space" {
  description = "Address pool handed to connected VPN clients."
  value       = local.deploy_vpn ? local.vpn_client_address_space : ""
}

# The Azure VPN Client does not receive a DNS server automatically. Add this IP
# to the downloaded azurevpnconfig.xml to resolve private endpoints.
output "vpn_client_dns_server" {
  description = "DNS server VPN clients must use: the firewall DNS proxy."
  value       = local.deploy_vpn ? module.firewall.resource.ip_configuration[0].private_ip_address : ""
}

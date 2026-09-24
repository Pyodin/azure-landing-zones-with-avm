output "virtual_network_id" {
  description = "Hub virtual network resource ID."
  value       = module.hub.virtual_network_resource_ids["primary"]
}

output "firewall_private_ip" {
  description = "Next hop for spoke default routes. Empty when deploy_firewall is false."
  value       = try(module.hub.firewall_private_ip_addresses["primary"], "")
}

output "private_dns_zone_resource_ids" {
  description = "Private DNS zones, keyed like local.private_dns_zones. Empty when local.private_dns_zones is."
  value       = try(module.hub.private_dns_zone_resource_ids["primary"], {})
}

output "vpn_client_address_space" {
  description = "Address pool handed to VPN clients. Empty when deploy_vpn is false."
  value       = local.deploy_vpn ? local.vpn_client_address_space : ""
}

output "dns_forwarder_ip" {
  description = "DNS server for VPN clients, to add to the VPN client profile. Empty when deploy_dns_forwarder is false."
  value       = try(module.dns_forwarder[0].ip_address, "")
}

# Mirrors the "connectivity" block in the management landing zone locals.
output "management_inputs" {
  description = "Values to copy into the management landing zone locals."
  value = {
    subscription_id         = local.subscription_id
    dns_resource_group_name = local.names.resource_group_dns
  }
}

# Mirrors the "connectivity" block in the subscriptions landing zone locals.
output "subscriptions_inputs" {
  description = "Values to copy into the subscriptions landing zone locals."
  value = {
    virtual_network_id = module.hub.virtual_network_resource_ids["primary"]
    has_vpn_gateway    = local.deploy_vpn
  }
}

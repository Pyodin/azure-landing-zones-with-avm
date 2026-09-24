output "budget_resource_ids" {
  description = "Monthly budget per subscription."
  value       = { for key, subscription in module.subscription : key => subscription.budget_resource_id }
}

# Mirrors the "spoke" block in each application landing zone's locals.
output "spoke_inputs" {
  description = "Values to copy into the matching application landing zone locals."
  value = {
    for key, subscription in module.subscription : key => {
      virtual_network_id         = subscription.virtual_network_resource_ids["spoke"]
      private_endpoint_subnet_id = "${subscription.virtual_network_resource_ids["spoke"]}/subnets/snet-pep-${key}-${local.location_short}-${local.instance}"
    } if can(local.subscriptions[key].spoke)
  }
}

output "budget_resource_ids" {
  description = "Monthly budget per subscription."
  value       = { for key, subscription in module.subscription : key => subscription.budget_resource_id }
}

output "spoke_virtual_network_ids" {
  description = "Spoke virtual network per subscription that has one."
  value = {
    for key, subscription in module.subscription :
    key => subscription.virtual_network_resource_ids["spoke"] if can(local.subscriptions[key].spoke)
  }
}

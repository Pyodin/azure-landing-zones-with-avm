output "resource_group_name" {
  description = "Management resource group holding the shared workspace."
  value       = module.resource_group_management.name
}

output "log_analytics_workspace_name" {
  description = "Central Log Analytics workspace name."
  value       = local.names.log_analytics_workspace
}

output "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace resource ID."
  value       = module.log_analytics.resource_id
}

output "management_group_ids" {
  description = "Every management group in the hierarchy, keyed the way the locals declare them."
  value       = local.management_group_ids
}

# Mirrors the "platform" block in the connectivity and application landing zones.
output "platform_inputs" {
  description = "Values to copy into the other landing zones' locals."
  value = {
    subscription_id                 = data.azurerm_client_config.current.subscription_id
    management_resource_group       = module.resource_group_management.name
    log_analytics_workspace_name    = local.names.log_analytics_workspace
    private_dns_policy_principal_id = azurerm_management_group_policy_assignment.private_dns_zones.identity[0].principal_id
  }
}

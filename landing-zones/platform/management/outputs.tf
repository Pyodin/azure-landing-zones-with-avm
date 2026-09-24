output "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace resource ID."
  value       = module.log_analytics.resource_id
}

output "management_group_resource_ids" {
  description = "Management group resource IDs, keyed by management group name."
  value       = module.alz.management_group_resource_ids
}

# Mirrors the "platform" block in the application landing zone.
output "platform_inputs" {
  description = "Values to copy into the application landing zone locals."
  value = {
    subscription_id              = local.subscription_id
    management_resource_group    = module.resource_group_management.name
    log_analytics_workspace_name = local.names.log_analytics_workspace
  }
}

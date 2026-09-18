output "resource_group_name" {
  description = "Resource group holding the state storage account."
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "Storage account every landing zone stores its state in."
  value       = local.names.storage_account
}

output "containers" {
  description = "State container per landing zone."
  value       = { for zone in local.landing_zones : zone => replace(zone, "/", "-") }
}

output "init_commands" {
  description = "How to initialise each landing zone against its backend."
  value = [
    for zone in local.landing_zones :
    "terraform -chdir=landing-zones/${zone} init -backend-config=backend.hcl"
  ]
}

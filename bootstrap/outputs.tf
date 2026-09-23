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

# None of these is a secret: the federated credential is the control.
output "github_variables" {
  description = "Repository variables GitHub Actions authenticates with."
  value = {
    AZURE_PLAN_CLIENT_ID    = module.cicd_plan.client_id
    AZURE_APPLY_CLIENT_ID   = module.cicd_apply.client_id
    AZURE_TENANT_ID         = data.azurerm_client_config.current.tenant_id
    TFSTATE_RESOURCE_GROUP  = module.resource_group.name
    TFSTATE_STORAGE_ACCOUNT = local.names.storage_account
    TFSTATE_SUBSCRIPTION_ID = local.subscription_id
  }
}

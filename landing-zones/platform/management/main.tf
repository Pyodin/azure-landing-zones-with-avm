data "azurerm_client_config" "current" {}

module "resource_group_management" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = local.names.resource_group_management
  location         = local.location
  enable_telemetry = local.enable_telemetry
  tags             = local.tags
}

# The single sink for every landing zone. CAF puts monitoring in the management
# landing zone rather than next to the network it happens to log first, so the
# hub and the spoke both read it through a data source.
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = local.names.log_analytics_workspace
  location            = local.location
  resource_group_name = module.resource_group_management.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  log_analytics_workspace_sku                             = "PerGB2018"
  log_analytics_workspace_retention_in_days               = local.log_retention_days
  log_analytics_workspace_allow_resource_only_permissions = false
  log_analytics_workspace_local_authentication_enabled    = false
}

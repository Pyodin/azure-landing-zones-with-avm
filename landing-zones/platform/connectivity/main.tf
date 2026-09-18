module "resource_group_connectivity" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = local.names.resource_group_connectivity
  location         = local.location
  enable_telemetry = local.enable_telemetry
  tags             = local.tags
}

module "resource_group_dns" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = local.names.resource_group_dns
  location         = local.location
  enable_telemetry = local.enable_telemetry
  tags             = local.tags
}

data "azurerm_client_config" "current" {}

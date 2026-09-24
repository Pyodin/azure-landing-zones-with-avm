data "azurerm_client_config" "current" {}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = local.names.resource_group
  location         = local.location
  enable_telemetry = local.enable_telemetry
  tags             = local.tags
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.0"

  name                = local.names.key_vault
  location            = local.location
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  sku_name                      = "standard"
  public_network_access_enabled = false
  purge_protection_enabled      = true # Enforce-GR-KeyVault denies a vault without it
  soft_delete_retention_days    = 7

  # In corp, Deploy-Private-DNS-Zones registers the endpoint in the hub's zone.
  private_endpoints_manage_dns_zone_group = false
  private_endpoints = {
    primary = {
      subnet_resource_id = local.spoke.private_endpoint_subnet_id
    }
  }

  role_assignments = {
    for key, principal_id in local.key_vault_secrets_officers : key => {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = principal_id
    }
  }
}

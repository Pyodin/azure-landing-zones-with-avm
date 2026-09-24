# Private-only test target for the VPN and the DNS forwarder.
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.0"

  name                = local.names.key_vault
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  sku_name                      = "standard"
  public_network_access_enabled = false
  purge_protection_enabled      = true # Enforce-GR-KeyVault denies a vault without it
  soft_delete_retention_days    = 7

  private_endpoints = {
    primary = {
      subnet_resource_id            = "${module.hub.virtual_network_resource_ids["primary"]}/subnets/${local.names.private_endpoint_subnet}"
      private_dns_zone_resource_ids = [module.hub.private_dns_zone_resource_ids["primary"]["key_vault"]]
    }
  }

  role_assignments = {
    for key, principal_id in local.key_vault_secrets_officers : key => {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = principal_id
    }
  }
}

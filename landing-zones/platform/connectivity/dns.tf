# Private DNS zones live in the connectivity landing zone and are linked to the
# hub network only. Spokes resolve through the firewall DNS proxy.
module "private_dns_zones" {
  source  = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version = "0.23.2"

  location         = local.location
  parent_id        = module.resource_group_dns.resource_id
  enable_telemetry = local.enable_telemetry
  tags             = local.tags

  private_link_private_dns_zones = {
    azure_key_vault    = { zone_name = "privatelink.vaultcore.azure.net" }
    azure_acr_registry = { zone_name = "privatelink.azurecr.io" }
    azure_storage_blob = { zone_name = "privatelink.blob.core.windows.net" }
    azure_aks_mgmt     = { zone_name = "privatelink.{regionName}.azmk8s.io" }
  }

  virtual_network_link_default_virtual_networks = {
    hub = {
      virtual_network_resource_id = module.hub_virtual_network.resource_id
    }
  }
}

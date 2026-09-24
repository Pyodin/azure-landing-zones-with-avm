locals {
  subscription_id = "1bc5bd17-f629-4778-9b62-4576f594cbb6"

  # Outputs of platform/identity.
  identity = {
    vpn_audience_client_id = "c5c5f83e-4fe8-413a-9995-4f01ca5bc179"
  }

  location       = "francecentral"
  location_short = "frc"
  environment    = "prod"
  instance       = "001"

  enable_telemetry = false

  # Everything off: the hub is a virtual network only. Turning the firewall or the
  # VPN on also requires has_firewall / has_vpn_gateway = true in spokes.
  deploy_firewall = false # Basic, ~€250/month
  deploy_vpn      = false # VpnGw1AZ, ~€130/month
  deploy_bastion  = false # Developer SKU is free; the jumpbox VM is ~€9/month

  jumpbox_size = "Standard_B2ats_v2"

  hub_address_space    = "10.0.0.0/16"
  spoke_address_spaces = ["10.1.0.0/16"]

  subnet_prefixes = {
    firewall            = "10.0.0.0/26"
    firewall_management = "10.0.0.64/26"
    gateway             = "10.0.2.0/27"
    management          = "10.0.3.0/27"
  }

  vpn_client_address_space = "172.20.0.0/24"

  # ~€0.43/zone/month. Empty: no zones and no DNS resource group. Linked to the hub;
  # spokes link their own virtual network to each zone. Mirror the list in
  # platform/management, and apply this root first.
  private_dns_zones = {
    # key_vault          = "privatelink.vaultcore.azure.net"
    # container_registry = "privatelink.azurecr.io"
    # storage_blob       = "privatelink.blob.core.windows.net"
    # aks                = "privatelink.{regionName}.azmk8s.io"
  }

  suffix = "${local.environment}-${local.location_short}-${local.instance}"

  names = {
    resource_group_connectivity = "rg-connectivity-${local.suffix}"
    resource_group_dns          = "rg-dns-${local.suffix}"
    virtual_network             = "vnet-hub-${local.suffix}"
    management_subnet           = "snet-management-${local.suffix}"
    management_nsg              = "nsg-management-${local.suffix}"
    firewall                    = "afw-hub-${local.suffix}"
    firewall_policy             = "afwp-hub-${local.suffix}"
    firewall_public_ip          = "pip-afw-hub-${local.suffix}"
    firewall_management_ip      = "pip-afw-mgmt-hub-${local.suffix}"
    route_table_firewall        = "rt-afw-hub-${local.suffix}"
    vpn_gateway                 = "vgw-hub-${local.suffix}"
    vpn_public_ip               = "pip-vgw-hub-${local.suffix}"
    bastion                     = "bas-hub-${local.suffix}"
    jumpbox                     = "vm-jump-${local.suffix}"
    jumpbox_nic                 = "nic-jump-${local.suffix}"
  }

  tags = {
    Environment = local.environment
    Workload    = "platform-connectivity"
    LandingZone = "platform"
    ManagedBy   = "Terraform"
    Repository  = "AzLandingZones"
  }
}

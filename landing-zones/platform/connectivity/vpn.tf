# Point-to-site gateway for administrators. Clients authenticate with Entra ID
# over OpenVPN, reach the spoke through gateway transit on the peering, and
# resolve private endpoints by pointing at the firewall DNS proxy.
module "vpn_gateway" {
  source  = "Azure/avm-ptn-vnetgateway/azurerm"
  version = "0.10.3"

  count = local.deploy_vpn ? 1 : 0

  name             = local.names.vpn_gateway
  location         = local.location
  parent_id        = module.resource_group_connectivity.resource_id
  enable_telemetry = local.enable_telemetry
  tags             = local.tags

  type           = "Vpn"
  vpn_type       = "RouteBased"
  sku            = "VpnGw1AZ"
  vpn_generation = "Generation2"

  virtual_network_id                = module.hub_virtual_network.resource_id
  subnet_creation_enabled           = false
  virtual_network_gateway_subnet_id = module.hub_virtual_network.subnets["gateway"].resource_id
  route_table_creation_enabled      = false

  ip_configurations = {
    default = {
      name = "ipconfig-default"
      public_ip = {
        name  = local.names.vpn_public_ip
        zones = [1, 2, 3]
      }
    }
  }

  vpn_point_to_site = {
    address_space        = [local.vpn_client_address_space]
    vpn_client_protocols = ["OpenVPN"]
    vpn_auth_types       = ["AAD"]
    aad_tenant           = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
    aad_audience         = local.identity.vpn_audience_client_id
    aad_issuer           = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
  }

  diagnostic_settings_virtual_network_gateway = {
    law = {
      name                  = "diag-to-law"
      workspace_resource_id = data.azurerm_log_analytics_workspace.platform.id
    }
  }
}

# The Microsoft-registered Azure VPN Client application belongs to Microsoft and
# is shared by every tenant, so it carries no assignments: a gateway pointed at
# it lets any account in the directory connect. The platform/identity landing
# zone exists to replace it with a custom audience of our own, and this is a
# warning rather than a precondition so the hub still applies on its own.
check "vpn_audience_is_tenant_owned" {
  assert {
    condition     = !local.deploy_vpn || local.identity.vpn_audience_client_id != "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"
    error_message = "The VPN gateway is using the Microsoft-registered Azure VPN Client application as its audience, so every account in the tenant can connect. Deploy landing-zones/platform/identity and copy its vpn_audience_client_id output into local.identity."
  }
}

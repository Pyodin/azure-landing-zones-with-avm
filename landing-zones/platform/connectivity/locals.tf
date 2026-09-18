locals {
  # The connectivity subscription. Every landing zone names the subscriptions
  # it touches, rather than inheriting one from the environment, so applying the
  # hub into the wrong subscription is not one forgotten export away.
  subscription_id = "33333333-3333-3333-3333-333333333333"

  # Outputs of the platform/management landing zone, which owns the shared
  # workspace and the policy layer.
  platform = {
    subscription_id              = "11111111-1111-1111-1111-111111111111"
    management_resource_group    = "rg-management-prod-weu-001"
    log_analytics_workspace_name = "log-platform-prod-weu-001"

    # Identity of the private DNS policy assignment, from the management landing
    # zone output of the same name. Leave empty until that landing zone is
    # deployed: the zones simply get no policy-driven writer until then.
    private_dns_policy_principal_id = ""
  }

  # Outputs of the platform/identity landing zone.
  identity = {
    # The gateway audience. This value is the Microsoft-registered Azure VPN
    # Client application, which every tenant shares and which carries no
    # assignments, so it lets any account in the directory connect. Replace it
    # with vpn_audience_client_id from the identity landing zone. The check
    # block in vpn.tf warns while it is still this value.
    vpn_audience_client_id = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"
  }

  location       = "westeurope"
  location_short = "weu"
  environment    = "prod"
  instance       = "001"

  enable_telemetry = false

  # Address plan. Spokes are declared here so the hub firewall can be built
  # without taking a dependency on any spoke state.
  hub_address_space    = "10.0.0.0/16"
  spoke_address_spaces = ["10.1.0.0/16"]

  subnet_prefixes = {
    firewall   = "10.0.0.0/26"
    bastion    = "10.0.1.0/26"
    gateway    = "10.0.2.0/26"
    management = "10.0.3.0/27"
  }

  # Bastion and the jumpbox are the most expensive optional pieces of the demo.
  # "az aks command invoke" reaches the private cluster without them.
  deploy_bastion = false
  jumpbox_size   = "Standard_B2s"

  # Point-to-site VPN for administrators. Turning this off also requires
  # has_vpn_gateway = false in the application landing zone, because its
  # peering asks the hub for gateway transit.
  deploy_vpn               = true
  vpn_client_address_space = "172.20.0.0/24"

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
    bastion                     = "bas-hub-${local.suffix}"
    bastion_public_ip           = "pip-bas-hub-${local.suffix}"
    jumpbox                     = "vm-jump-${local.suffix}"
    jumpbox_nic                 = "nic-jump-${local.suffix}"
    vpn_gateway                 = "vgw-hub-${local.suffix}"
    vpn_public_ip               = "pip-vgw-hub-${local.suffix}"
  }

  tags = {
    Environment = local.environment
    Workload    = "platform-connectivity"
    LandingZone = "platform"
    ManagedBy   = "Terraform"
    Repository  = "AzLandingZones"
  }
}

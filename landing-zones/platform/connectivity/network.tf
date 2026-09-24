module "management_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = local.names.management_nsg
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  security_rules = {
    # Bastion Developer connects from the Azure platform address, not from a subnet.
    allow_ssh_from_bastion = {
      name                       = "AllowSshFromBastion"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_address_prefix      = "168.63.129.16"
      source_port_range          = "*"
      destination_address_prefix = local.subnet_prefixes.management
      destination_port_range     = "22"
    }
    deny_all_inbound = {
      name                       = "DenyAllInbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 4096
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    }
  }
}

module "hub" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = "0.17.5"

  enable_telemetry = local.enable_telemetry
  tags             = local.tags

  default_naming_convention = {
    virtual_network_name                              = local.names.virtual_network
    firewall_name                                     = local.names.firewall
    firewall_policy_name                              = local.names.firewall_policy
    firewall_public_ip_name                           = local.names.firewall_public_ip
    firewall_management_public_ip_name                = local.names.firewall_management_ip
    route_table_firewall_name                         = local.names.route_table_firewall
    virtual_network_gateway_vpn_name                  = local.names.vpn_gateway
    virtual_network_gateway_vpn_public_ip_name        = local.names.vpn_public_ip
    virtual_network_gateway_vpn_ip_configuration_name = "ipconfig-vgw-hub"
  }

  # Defaults to true: a DDoS Network Protection plan is ~€2,500/month.
  hub_and_spoke_networks_settings = {
    enabled_resources = {
      ddos_protection_plan = false
    }
  }

  hub_virtual_networks = {
    primary = {
      location          = local.location
      default_parent_id = module.resource_group_connectivity.resource_id

      # Everything not listed defaults to true, including an ExpressRoute
      # gateway and a DNS Private Resolver (~€155/month).
      enabled_resources = {
        firewall                              = local.deploy_firewall
        firewall_policy                       = local.deploy_firewall
        bastion                               = false
        virtual_network_gateway_express_route = false
        virtual_network_gateway_vpn           = local.deploy_vpn
        private_dns_zones                     = length(local.private_dns_zones) > 0
        private_dns_resolver                  = false
        dns_resolver_policy                   = false
        nat_gateway                           = false
      }

      hub_virtual_network = {
        address_space                    = [local.hub_address_space]
        mesh_peering_enabled             = false
        route_table_user_subnets_enabled = false

        subnets = {
          management = {
            name             = local.names.management_subnet
            address_prefixes = [local.subnet_prefixes.management]
            network_security_group = {
              id = module.management_nsg.resource_id
            }
            route_table = {
              assign_generated_route_table = false
            }
            # The jumpbox installs its tooling from the internet.
            default_outbound_access_enabled = true
          }
          dns_forwarder = {
            name             = local.names.dns_forwarder_subnet
            address_prefixes = [local.subnet_prefixes.dns_forwarder]
            delegations = [{
              name = "aci"
              service_delegation = {
                name = "Microsoft.ContainerInstance/containerGroups"
              }
            }]
            route_table = {
              assign_generated_route_table = false
            }
            # The container group pulls its image from mcr.microsoft.com.
            default_outbound_access_enabled = true
          }
        }
      }

      # Basic gets its management subnet and second public IP from the module.
      # It cannot proxy DNS, so spokes link to the private DNS zones instead.
      firewall = {
        sku_tier                         = "Basic"
        subnet_address_prefix            = local.subnet_prefixes.firewall
        management_subnet_address_prefix = local.subnet_prefixes.firewall_management
      }

      firewall_policy = {
        sku = "Basic"
      }

      virtual_network_gateways = {
        subnet_address_prefix = local.subnet_prefixes.gateway

        vpn = {
          sku                       = "VpnGw1AZ"
          vpn_generation            = "Generation2"
          vpn_active_active_enabled = false
          ip_configurations = {
            default = {}
          }
          vpn_point_to_site = {
            address_space        = [local.vpn_client_address_space]
            vpn_client_protocols = ["OpenVPN"]
            vpn_auth_types       = ["AAD"]
            aad_tenant           = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
            aad_audience         = local.identity.vpn_audience_client_id
            aad_issuer           = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
          }
        }
      }

      private_dns_zones = {
        parent_id                      = one(module.resource_group_dns[*].resource_id)
        auto_registration_zone_enabled = false
        private_link_private_dns_zones = {
          for key, zone_name in local.private_dns_zones : key => { zone_name = zone_name }
        }
      }
    }
  }
}

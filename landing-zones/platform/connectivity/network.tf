module "management_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = local.names.management_nsg
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  security_rules = {
    allow_ssh_from_bastion = {
      name                       = "AllowSshFromBastion"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_address_prefix      = local.subnet_prefixes.bastion
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

  diagnostic_settings = {
    law = {
      name                  = "diag-to-law"
      workspace_resource_id = data.azurerm_log_analytics_workspace.platform.id
    }
  }
}

module "hub_virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.22.2"

  name             = local.names.virtual_network
  location         = local.location
  parent_id        = module.resource_group_connectivity.resource_id
  address_space    = [local.hub_address_space]
  enable_telemetry = local.enable_telemetry
  tags             = local.tags

  subnets = {
    firewall = {
      name           = "AzureFirewallSubnet"
      address_prefix = local.subnet_prefixes.firewall
    }
    bastion = {
      name           = "AzureBastionSubnet"
      address_prefix = local.subnet_prefixes.bastion
    }
    gateway = {
      name           = "GatewaySubnet"
      address_prefix = local.subnet_prefixes.gateway
    }
    management = {
      name           = local.names.management_subnet
      address_prefix = local.subnet_prefixes.management
      network_security_group = {
        id = module.management_nsg.resource_id
      }
    }
  }

  diagnostic_settings = {
    law = {
      name                  = "diag-to-law"
      workspace_resource_id = data.azurerm_log_analytics_workspace.platform.id
    }
  }
}

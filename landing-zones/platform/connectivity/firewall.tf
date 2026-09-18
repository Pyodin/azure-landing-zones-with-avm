module "firewall_public_ip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  name                = local.names.firewall_public_ip
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  allocation_method = "Static"
  sku               = "Standard"
  zones             = ["1", "2", "3"]

  diagnostic_settings = {
    law = {
      name                  = "diag-to-law"
      workspace_resource_id = data.azurerm_log_analytics_workspace.platform.id
    }
  }
}

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                = local.names.firewall_policy
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  firewall_policy_sku                      = "Standard"
  firewall_policy_threat_intelligence_mode = "Alert"

  # The DNS proxy lets spokes use the firewall as their DNS server, so private
  # endpoint records resolve through the zones linked to the hub network.
  firewall_policy_dns = {
    proxy_enabled = true
  }
}

module "firewall_rules" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version = "0.3.4"

  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource_id
  firewall_policy_rule_collection_group_name               = "rcg-spoke-egress"
  firewall_policy_rule_collection_group_priority           = 500

  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      name     = "nrc-aks-control-plane"
      priority = 100
      action   = "Allow"
      rule = [
        {
          name                  = "aks-api-server"
          protocols             = ["TCP"]
          source_addresses      = local.spoke_address_spaces
          destination_addresses = ["AzureCloud.${local.location}"]
          destination_ports     = ["443", "9000"]
        },
        {
          name                  = "aks-tunnel"
          protocols             = ["UDP"]
          source_addresses      = local.spoke_address_spaces
          destination_addresses = ["AzureCloud.${local.location}"]
          destination_ports     = ["1194"]
        },
        {
          name                  = "ntp"
          protocols             = ["UDP"]
          source_addresses      = local.spoke_address_spaces
          destination_addresses = ["*"]
          destination_ports     = ["123"]
        },
      ]
    },
    {
      name     = "nrc-azure-platform"
      priority = 200
      action   = "Allow"
      rule = [
        {
          name                  = "entra-id"
          protocols             = ["TCP"]
          source_addresses      = local.spoke_address_spaces
          destination_addresses = ["AzureActiveDirectory"]
          destination_ports     = ["443"]
        },
        {
          name                  = "azure-monitor"
          protocols             = ["TCP"]
          source_addresses      = local.spoke_address_spaces
          destination_addresses = ["AzureMonitor"]
          destination_ports     = ["443"]
        },
        {
          name                  = "container-registries"
          protocols             = ["TCP"]
          source_addresses      = local.spoke_address_spaces
          destination_addresses = ["AzureContainerRegistry", "MicrosoftContainerRegistry"]
          destination_ports     = ["443"]
        },
      ]
    },
  ]

  firewall_policy_rule_collection_group_application_rule_collection = [
    {
      name     = "arc-aks-egress"
      priority = 300
      action   = "Allow"
      rule = [
        {
          name                  = "aks-service-tag"
          source_addresses      = local.spoke_address_spaces
          destination_fqdn_tags = ["AzureKubernetesService"]
        },
        {
          name             = "node-os-updates"
          source_addresses = local.spoke_address_spaces
          destination_fqdns = [
            "packages.microsoft.com",
            "azure.archive.ubuntu.com",
            "security.ubuntu.com",
            "changelogs.ubuntu.com",
            "packages.aks.azure.com",
          ]
          protocols = [
            { type = "Http", port = 80 },
            { type = "Https", port = 443 },
          ]
        },
      ]
    },
  ]
}

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"

  name                = local.names.firewall
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  firewall_sku_name  = "AZFW_VNet"
  firewall_sku_tier  = "Standard"
  firewall_policy_id = module.firewall_policy.resource_id
  firewall_zones     = ["1", "2", "3"]

  ip_configurations = {
    default = {
      name                 = "ipconfig-default"
      subnet_id            = module.hub_virtual_network.subnets["firewall"].resource_id
      public_ip_address_id = module.firewall_public_ip.public_ip_id
    }
  }

  diagnostic_settings = {
    law = {
      name                  = "diag-to-law"
      workspace_resource_id = data.azurerm_log_analytics_workspace.platform.id
    }
  }

  depends_on = [module.firewall_rules]
}

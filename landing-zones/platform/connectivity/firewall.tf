module "firewall_rules" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  version = "0.3.4"

  count = local.deploy_firewall ? 1 : 0

  firewall_policy_rule_collection_group_firewall_policy_id = module.hub.firewall_policies["primary"].id
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

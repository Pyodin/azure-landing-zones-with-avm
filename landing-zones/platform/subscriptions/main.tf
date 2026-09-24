# Budgets must start on the first of a month no earlier than the current one.
resource "time_static" "budget_start" {}

module "subscription" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "0.3.2"

  for_each = local.subscriptions

  location         = local.location
  subscription_id  = each.value.subscription_id
  enable_telemetry = local.enable_telemetry

  # Only where set: writing a platform subscription's association here too would
  # move it back and forth with platform/management on every apply.
  subscription_management_group_association_enabled = try(each.value.management_group_id, null) != null
  subscription_management_group_id                  = try(each.value.management_group_id, null)

  budget_enabled = true
  budgets = {
    monthly = {
      name              = "budget-${each.key}-monthly"
      amount            = each.value.budget_amount
      time_grain        = "Monthly"
      time_period_start = formatdate("YYYY-MM-01'T'00:00:00Z", time_static.budget_start.rfc3339)
      time_period_end   = "2035-12-31T00:00:00Z"
      notifications     = local.budget_notifications
    }
  }

  resource_group_creation_enabled = can(each.value.spoke)
  resource_groups = can(each.value.spoke) ? {
    network = {
      name = "rg-network-${each.key}-${local.location_short}-${local.instance}"
    }
  } : {}

  # Deny-Subnet-Without-Nsg applies to every landing zone subnet.
  network_security_group_enabled = can(each.value.spoke)
  network_security_groups = can(each.value.spoke) ? {
    private_endpoints = {
      name               = "nsg-pep-${each.key}-${local.location_short}-${local.instance}"
      resource_group_key = "network"
    }
  } : {}

  virtual_network_enabled = can(each.value.spoke)
  virtual_networks = can(each.value.spoke) ? {
    spoke = {
      name               = "vnet-spoke-${each.key}-${local.location_short}-${local.instance}"
      address_space      = [each.value.spoke.address_space]
      resource_group_key = "network"

      subnets = {
        private_endpoints = {
          name             = "snet-pep-${each.key}-${local.location_short}-${local.instance}"
          address_prefixes = [each.value.spoke.subnet_prefixes.private_endpoints]
          network_security_group = {
            key_reference = "private_endpoints"
          }
        }
      }

      hub_peering_enabled      = true
      hub_network_resource_id  = local.connectivity.virtual_network_id
      hub_peering_name_tohub   = "peer-spoke-${each.key}-to-hub"
      hub_peering_name_fromhub = "peer-hub-to-spoke-${each.key}"
      hub_peering_options_tohub = {
        use_remote_gateways = local.connectivity.has_vpn_gateway
      }
      hub_peering_options_fromhub = {
        allow_gateway_transit = local.connectivity.has_vpn_gateway
      }
    }
  } : {}
}

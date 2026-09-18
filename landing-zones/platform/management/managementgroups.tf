# The tenant root group, which nobody creates and nobody deletes. Its name is
# the tenant ID.
data "azurerm_management_group" "tenant_root" {
  name = data.azurerm_client_config.current.tenant_id
}

# An intermediate root under the tenant root, never the tenant root itself.
# Policy assigned at the tenant root reaches every subscription in the tenant
# including ones this platform does not own, and the tenant root cannot be
# deleted if the design turns out wrong.
resource "azurerm_management_group" "intermediate_root" {
  name                       = local.management_group_prefix
  display_name               = "Azure landing zones"
  parent_management_group_id = data.azurerm_management_group.tenant_root.id
}

resource "azurerm_management_group" "tier1" {
  for_each = local.management_groups_tier1

  name                       = "${local.management_group_prefix}-${each.value.name}"
  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.intermediate_root.id
}

resource "azurerm_management_group" "tier2" {
  for_each = local.management_groups_tier2

  name                       = "${local.management_group_prefix}-${each.value.name}"
  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.tier1[each.value.parent].id
}

# Moving a subscription is a tenant-level operation: it needs Management Group
# Contributor on the target group and Owner on the subscription. Placement is
# declared per management group so a real tenant lists one subscription per
# landing zone rather than a single flat list.
resource "azurerm_management_group_subscription_association" "this" {
  for_each = merge([
    for management_group_key, subscription_ids in local.management_group_subscriptions : {
      for subscription_id in subscription_ids :
      "${management_group_key}/${subscription_id}" => {
        management_group_key = management_group_key
        subscription_id      = subscription_id
      }
    }
  ]...)


  # Sandbox and decommissioned sit at tier 1, everything else at tier 2.
  management_group_id = try(
    azurerm_management_group.tier2[each.value.management_group_key].id,
    azurerm_management_group.tier1[each.value.management_group_key].id,
  )
  subscription_id = "/subscriptions/${each.value.subscription_id}"
}

# Budgets must start on the first of a month no earlier than the current one.
resource "time_static" "budget_start" {}

module "subscription" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "0.3.2"

  for_each = local.subscriptions

  location         = local.location
  subscription_id  = each.value
  enable_telemetry = local.enable_telemetry

  # platform/management places these through avm-ptn-alz. Both writing the
  # association would move the subscription back and forth on every apply.
  subscription_management_group_association_enabled = false

  budget_enabled = true
  budgets = {
    monthly = {
      name              = "budget-${each.key}-monthly"
      amount            = local.budget_amounts[each.key]
      time_grain        = "Monthly"
      time_period_start = formatdate("YYYY-MM-01'T'00:00:00Z", time_static.budget_start.rfc3339)
      time_period_end   = "2035-12-31T00:00:00Z"
      notifications = {
        actual_80 = {
          enabled       = true
          operator      = "GreaterThan"
          threshold     = 80
          contact_roles = ["Owner"]
        }
        forecast_100 = {
          enabled        = true
          operator       = "GreaterThan"
          threshold      = 100
          threshold_type = "Forecasted"
          contact_roles  = ["Owner"]
        }
      }
    }
  }
}

locals {
  # Outputs of platform/connectivity.
  connectivity = {
    virtual_network_id = "/subscriptions/1bc5bd17-f629-4778-9b62-4576f594cbb6/resourceGroups/rg-connectivity-prod-frc-001/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-frc-001"
    has_vpn_gateway    = true
  }

  location         = "francecentral"
  location_short   = "frc"
  instance         = "001"
  enable_telemetry = false

  # Existing subscriptions. Budgets in the billing currency, monthly.
  #   management_group_id: placement. Omitted for platform subscriptions, which
  #                        platform/management places.
  #   spoke:               a virtual network peered to the hub. Its address space
  #                        must be listed in connectivity's spoke_address_spaces.
  subscriptions = {
    management = {
      subscription_id = "535e631d-1f74-4fd4-b38e-fbd577b8c817"
      budget_amount   = 20
    }
    connectivity = {
      subscription_id = "1bc5bd17-f629-4778-9b62-4576f594cbb6"
      budget_amount   = 20
    }
    dev = {
      subscription_id     = "a3dd6f19-8aca-4245-828f-968f9de0c43e"
      budget_amount       = 20
      management_group_id = "alz-corp"
    }
  }

  budget_notifications = {
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

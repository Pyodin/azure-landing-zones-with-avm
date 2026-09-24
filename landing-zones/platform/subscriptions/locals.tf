locals {
  # Assumed to exist. Placement in the hierarchy belongs to platform/management.
  subscriptions = {
    management   = "535e631d-1f74-4fd4-b38e-fbd577b8c817"
    connectivity = "1bc5bd17-f629-4778-9b62-4576f594cbb6"
  }

  location         = "francecentral"
  enable_telemetry = false

  # Monthly, in the billing currency.
  budget_amounts = {
    management   = 20
    connectivity = 50
  }
}

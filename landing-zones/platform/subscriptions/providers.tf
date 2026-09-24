# Every resource here is addressed by a full subscription-scoped ID.
provider "azapi" {
  subscription_id = local.subscriptions.management
}

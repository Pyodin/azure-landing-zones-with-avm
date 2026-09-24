provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}

# Left unset, azapi resolves the subscription to "" and the apply fails.
provider "azapi" {
  subscription_id = local.subscription_id
}

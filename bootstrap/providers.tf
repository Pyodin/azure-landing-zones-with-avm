provider "azurerm" {
  subscription_id = local.subscription_id

  # Shared keys are disabled on the state account, so the provider must reach
  # the data plane with Entra ID when it looks at anything below the account.
  storage_use_azuread = true

  features {}
}

provider "azapi" {
  subscription_id = local.subscription_id
}

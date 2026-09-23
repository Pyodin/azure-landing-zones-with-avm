provider "azurerm" {
  subscription_id = local.subscription_id

  # Shared keys are disabled on the state account, so the data plane needs Entra ID.
  storage_use_azuread = true

  features {}
}

provider "azapi" {
  subscription_id = local.subscription_id
}

provider "azuread" {}

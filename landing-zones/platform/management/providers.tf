provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}

# Left unset, azapi resolves the subscription to "" and the apply fails.
provider "azapi" {
  subscription_id = local.subscription_id
}

provider "alz" {
  library_references = [
    { path = "platform/alz", ref = "2026.08.1" },
    { custom_url = "${path.root}/lib" },
  ]
}

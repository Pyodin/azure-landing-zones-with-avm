provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}

# Reads the shared workspace and grants the policy identity access to the DNS
# zones, both in the management subscription.
provider "azurerm" {
  alias           = "platform"
  subscription_id = local.platform.subscription_id
  features {}
}

provider "azapi" {
  subscription_id = local.subscription_id
}

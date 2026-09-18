terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }

  # No backend, on purpose. This root creates the storage account every other
  # root stores its state in, so it cannot store its own state there. Its state
  # stays local and gitignored, which is the usual answer to that circularity.
  #
  # Losing it costs nothing: everything here is idempotent and importable, and
  # the storage account outlives the state file that describes it.
}

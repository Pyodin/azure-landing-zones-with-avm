terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
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

  # No backend: this root creates the storage account the others store state in.
  # Its own state stays local and gitignored.
}

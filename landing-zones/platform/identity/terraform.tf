terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Configuration comes from backend.hcl, which the bootstrap root writes. The block
  # is deliberately empty: the storage account name depends on the tenant this is
  # deployed into, so it is not a constant that belongs in the repository.
  #
  #   terraform init -backend-config=backend.hcl
  backend "azurerm" {}
}

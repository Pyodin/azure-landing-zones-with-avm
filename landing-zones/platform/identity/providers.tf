# Directory objects belong to a tenant, not a subscription, which is why this
# landing zone is a root of its own and carries no azurerm provider at all.
# Tenant comes from the authenticated Azure CLI context.
provider "azuread" {}

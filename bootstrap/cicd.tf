locals {
  tenant_root_group = "/providers/Microsoft.Management/managementGroups/${data.azurerm_client_config.current.tenant_id}"
}

# Plan runs on unreviewed pull request code, and Terraform executes the provider
# binaries that code names. This identity is that blast radius, so it only reads.
module "cicd_plan" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.2"

  name                = local.names.cicd_plan
  location            = local.location
  resource_group_name = module.resource_group.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  federated_identity_credentials = {
    for key, subject in local.cicd_plan_subjects : key => {
      name     = key
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
      subject  = "repo:${local.github_repository}:${subject}"
    }
  }

  role_assignments = {
    tenant_root = {
      role_definition_id_or_name       = "Reader"
      scope                            = local.tenant_root_group
      skip_service_principal_aad_check = true
    }

    # Contributor, not Reader: plan takes a lease on the state blob.
    state = {
      role_definition_id_or_name       = "Storage Blob Data Contributor"
      scope                            = module.storage_account.resource_id
      skip_service_principal_aad_check = true
    }
  }
}

# Reachable only from a job declaring the production environment.
module "cicd_apply" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.2"

  name                = local.names.cicd_apply
  location            = local.location
  resource_group_name = module.resource_group.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  federated_identity_credentials = {
    for key, subject in local.cicd_apply_subjects : key => {
      name     = key
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
      subject  = "repo:${local.github_repository}:${subject}"
    }
  }

  role_assignments = {
    # platform/management creates management groups and grants roles at this scope.
    # Narrowing this is the first thing to do on a real tenant.
    tenant_root = {
      role_definition_id_or_name       = "Owner"
      scope                            = local.tenant_root_group
      skip_service_principal_aad_check = true
    }

    state = {
      role_definition_id_or_name       = "Storage Blob Data Owner"
      scope                            = module.storage_account.resource_id
      skip_service_principal_aad_check = true
    }
  }
}

data "azuread_service_principal" "microsoft_graph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

# Azure RBAC does not reach the directory: platform/identity needs Graph.
resource "azuread_app_role_assignment" "cicd_plan_graph" {
  for_each = local.cicd_plan_graph_app_roles

  app_role_id         = each.value
  principal_object_id = module.cicd_plan.principal_id
  resource_object_id  = data.azuread_service_principal.microsoft_graph.object_id
}

# OwnedBy: only applications this identity created itself.
resource "azuread_app_role_assignment" "cicd_apply_graph" {
  for_each = local.cicd_apply_graph_app_roles

  app_role_id         = each.value
  principal_object_id = module.cicd_apply.principal_id
  resource_object_id  = data.azuread_service_principal.microsoft_graph.object_id
}

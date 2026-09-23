data "azurerm_client_config" "current" {}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = local.names.resource_group
  location         = local.location
  enable_telemetry = local.enable_telemetry
  tags             = local.tags
}

# The data plane is reached from GitHub-hosted runners: no private endpoint, and no
# address range worth allow-listing. Shared keys are off, so a caller still needs an
# Entra token and a role assignment.
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.10.0"

  name             = local.names.storage_account
  location         = local.location
  parent_id        = module.resource_group.resource_id
  enable_telemetry = local.enable_telemetry
  tags             = local.tags

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  public_network_access_enabled = true
  shared_access_key_enabled     = false

  # The module defaults this to Deny, which refuses every caller including the runners.
  network_rules = {
    default_action = "Allow"
  }

  default_to_oauth_authentication = true
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties = {
    versioning_enabled = true
    delete_retention_policy = {
      enabled = true
      days    = local.retention_days
    }
    container_delete_retention_policy = {
      enabled = true
      days    = local.retention_days
    }
  }

  containers = {
    for zone in local.landing_zones : zone => {
      name = replace(zone, "/", "-")
    }
  }

  # Control plane Owner does not grant access to a blob.
  role_assignments = {
    deployer = {
      role_definition_id_or_name = "Storage Blob Data Owner"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
}

# A backend cannot be configured from a computed value, so it is written out instead.
resource "local_file" "backend" {
  for_each = toset(local.landing_zones)

  filename        = "${path.module}/../landing-zones/${each.value}/backend.hcl"
  file_permission = "0644"

  content = <<-EOT
    # Written by the bootstrap root. Not committed.
    resource_group_name  = "${module.resource_group.name}"
    storage_account_name = "${local.names.storage_account}"
    container_name       = "${replace(each.value, "/", "-")}"
    key                  = "terraform.tfstate"
    subscription_id      = "${local.subscription_id}"
    tenant_id            = "${data.azurerm_client_config.current.tenant_id}"
    use_azuread_auth     = true
  EOT

  depends_on = [module.storage_account]
}

data "azurerm_client_config" "current" {}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = local.names.resource_group
  location         = local.location
  enable_telemetry = local.enable_telemetry
  tags             = local.tags
}

# Shared keys are disabled, so Terraform reaches the data plane with Entra ID.
# Public network access stays on because Terraform runs from a laptop or a hosted
# agent; a private endpoint here means a self-hosted agent inside the network.
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
  account_replication_type = "ZRS"
  access_tier              = "Hot"

  public_network_access_enabled   = true
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Versioning and soft delete are the whole point of keeping state in a blob. A
  # corrupted apply is recoverable from a previous version, a deleted container
  # for as long as the retention window.
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
      # platform/connectivity becomes platform-connectivity, which is a valid
      # container name and reads the same as the directory it belongs to.
      name = replace(zone, "/", "-")
    }
  }

  # Control plane Owner does not grant access to a blob, and never has. Whoever
  # runs this needs the data role to read and write state afterwards.
  role_assignments = {
    deployer = {
      role_definition_id_or_name = "Storage Blob Data Owner"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
}

# Terraform cannot configure its own backend from a computed value, so the
# configuration is written out instead and passed with -backend-config. The file
# is gitignored: it names a storage account belonging to one tenant.
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
    use_azuread_auth     = true
  EOT

  depends_on = [module.storage_account]
}

locals {
  # Subscription that holds the state storage account. In the CAF layout this is
  # the management subscription, which already owns the platform's shared services.
  subscription_id = "11111111-1111-1111-1111-111111111111"

  location       = "westeurope"
  location_short = "weu"
  environment    = "prod"
  instance       = "001"

  enable_telemetry = false

  # Soft delete window for blobs and for containers.
  retention_days = 30

  # One container per landing zone rather than one container and different keys:
  # a container is an RBAC boundary, so a team can be granted access to its own
  # state and nothing else. Add a landing zone here when you add a directory.
  landing_zones = [
    "platform/management",
    "platform/identity",
    "platform/connectivity",
    "application/workload-aks",
  ]

  suffix = "${local.environment}-${local.location_short}-${local.instance}"

  names = {
    resource_group  = "rg-tfstate-${local.suffix}"
    storage_account = "sttfstate${local.environment}${local.location_short}${local.instance}"
  }

  tags = {
    Environment = local.environment
    Workload    = "tfstate"
    LandingZone = "platform"
    ManagedBy   = "Terraform"
    Repository  = "AzLandingZones"
  }
}

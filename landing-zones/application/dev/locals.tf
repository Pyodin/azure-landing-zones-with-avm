locals {
  subscription_id = "a3dd6f19-8aca-4245-828f-968f9de0c43e"

  # Outputs of platform/subscriptions, spoke_inputs["dev"].
  spoke = {
    private_endpoint_subnet_id = "/subscriptions/a3dd6f19-8aca-4245-828f-968f9de0c43e/resourceGroups/rg-network-dev-frc-001/providers/Microsoft.Network/virtualNetworks/vnet-spoke-dev-frc-001/subnets/snet-pep-dev-frc-001"
  }

  location       = "francecentral"
  location_short = "frc"
  environment    = "dev"
  workload       = "app"
  instance       = "001"

  enable_telemetry = false

  # Data plane access to the test vault, principal object IDs.
  key_vault_secrets_officers = {
    paul_bourhis = "da125852-ccf4-4346-9ac6-e952f20c2dfe"
  }

  suffix = "${local.workload}-${local.environment}-${local.location_short}-${local.instance}"

  # Globally unique names carry the subscription's first characters.
  unique = substr(local.subscription_id, 0, 4)

  names = {
    resource_group = "rg-${local.suffix}"
    key_vault      = "kv-${local.workload}-${local.environment}-${local.location_short}-${local.unique}"
  }

  tags = {
    Environment = local.environment
    Workload    = local.workload
    LandingZone = "application"
    ManagedBy   = "Terraform"
    Repository  = "AzLandingZones"
  }
}

locals {
  subscription_id = "535e631d-1f74-4fd4-b38e-fbd577b8c817"

  connectivity = {
    subscription_id         = "1bc5bd17-f629-4778-9b62-4576f594cbb6"
    dns_resource_group_name = "rg-dns-prod-frc-001"
  }

  location       = "francecentral"
  location_short = "frc"
  environment    = "prod"
  instance       = "001"

  enable_telemetry = false

  security_contact_email = "paul.bourhis@bhs-consulting.com"

  log_retention_days = 30
  log_daily_quota_gb = 1

  # Must match the ids in lib/alz_custom.alz_architecture_definition.yaml.
  management_group_ids = {
    root         = "alz"
    management   = "alz-management"
    connectivity = "alz-connectivity"
    corp         = "alz-corp"
    online       = "alz-online"
  }

  suffix = "${local.environment}-${local.location_short}-${local.instance}"

  names = {
    resource_group_management = "rg-management-${local.suffix}"
    log_analytics_workspace   = "log-platform-${local.suffix}"
  }

  # Composed rather than read from module outputs: avm-ptn-alz marks every
  # assignment for replacement when an input is unknown at plan time.
  log_analytics_workspace_id = join("/", [
    "/subscriptions/${local.subscription_id}",
    "resourceGroups/${local.names.resource_group_management}",
    "providers/Microsoft.OperationalInsights/workspaces/${local.names.log_analytics_workspace}",
  ])

  private_dns_zone_id_prefix = join("/", [
    "/subscriptions/${local.connectivity.subscription_id}",
    "resourceGroups/${local.connectivity.dns_resource_group_name}",
    "providers/Microsoft.Network/privateDnsZones",
  ])

  tags = {
    Environment = local.environment
    Workload    = "platform-management"
    LandingZone = "platform"
    ManagedBy   = "Terraform"
    Repository  = "AzLandingZones"
  }
}

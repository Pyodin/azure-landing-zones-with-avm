locals {
  # The subscriptions this platform governs. They are assumed to exist: this
  # repository places them in the hierarchy and governs them, it does not vend
  # them. Replace the four placeholders with your own before applying anything.
  #
  # Each landing zone repeats the IDs it needs in its own locals rather than
  # reading them from here, because no root reads another root's state.
  subscriptions = {
    management   = "11111111-1111-1111-1111-111111111111"
    identity     = "22222222-2222-2222-2222-222222222222"
    connectivity = "33333333-3333-3333-3333-333333333333"
    workload_aks = "44444444-4444-4444-4444-444444444444"
  }

  subscription_id = local.subscriptions.management

  # The connectivity landing zone owns the private DNS zones the policy points
  # at. Names only: the resource IDs are composed in policy.tf.
  connectivity = {
    dns_resource_group_name = "rg-dns-prod-weu-001"
  }

  location       = "westeurope"
  location_short = "weu"
  environment    = "prod"
  instance       = "001"

  enable_telemetry = false

  log_retention_days = 30

  # Management group hierarchy, from the CAF reference architecture. A name is
  # permanent and appears in every policy assignment scope, so it is chosen once
  # and never changed; a display name is only what the portal shows.
  management_group_prefix = "alz"

  # Children of the intermediate root.
  management_groups_tier1 = {
    platform = {
      name         = "platform"
      display_name = "Platform"
    }
    landing_zones = {
      name         = "landingzones"
      display_name = "Landing zones"
    }
    sandbox = {
      name         = "sandbox"
      display_name = "Sandbox"
    }
    decommissioned = {
      name         = "decommissioned"
      display_name = "Decommissioned"
    }
  }

  # Their children. A for_each cannot reference the resource it belongs to, and
  # the hierarchy is only three levels deep, so the tiers are declared apart
  # rather than resolved from one recursive map.
  management_groups_tier2 = {
    platform_management = {
      name         = "platform-management"
      display_name = "Management"
      parent       = "platform"
    }
    platform_connectivity = {
      name         = "platform-connectivity"
      display_name = "Connectivity"
      parent       = "platform"
    }
    platform_identity = {
      name         = "platform-identity"
      display_name = "Identity"
      parent       = "platform"
    }
    landing_zones_corp = {
      name         = "landingzones-corp"
      display_name = "Corp"
      parent       = "landing_zones"
    }
    landing_zones_online = {
      name         = "landingzones-online"
      display_name = "Online"
      parent       = "landing_zones"
    }
  }

  # Where each subscription lands. The identity subscription is placed even
  # though the identity landing zone deploys nothing into it: that landing zone
  # creates directory objects, which belong to the tenant and not to any
  # subscription. The management group and the subscription are there for the
  # day it grows domain controllers or Entra Domain Services.
  management_group_subscriptions = {
    platform_management = [
      local.subscriptions.management,
    ]
    platform_identity = [
      local.subscriptions.identity,
    ]
    platform_connectivity = [
      local.subscriptions.connectivity,
    ]
    landing_zones_corp = [
      local.subscriptions.workload_aks,
    ]
  }

  # Management groups the two initiatives are assigned to. The baseline applies
  # to everything under the intermediate root; the private DNS remediation only
  # has to reach subscriptions that host workloads.
  baseline_assignment_scope    = "alz"
  private_dns_assignment_scope = "landing_zones"

  suffix = "${local.environment}-${local.location_short}-${local.instance}"

  names = {
    resource_group_management = "rg-management-${local.suffix}"
    log_analytics_workspace   = "log-platform-${local.suffix}"

    # Kept at the ALZ names. A policy assignment name is capped at 24
    # characters at management group scope, which the longer of these is
    # exactly.
    private_dns_policy = "Deploy-Private-DNS-Zones"
    baseline_policy    = "Enforce-Baseline"
  }

  tags = {
    Environment = local.environment
    Workload    = "platform-management"
    LandingZone = "platform"
    ManagedBy   = "Terraform"
    Repository  = "AzLandingZones"
  }
}

data "azapi_client_config" "current" {}

# Hierarchy and archetypes come from lib/. The overrides there strip the ALZ
# assignments that bill per VM or per GB.
module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.21.0"

  architecture_name  = "alz_custom"
  location           = local.location
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = local.enable_telemetry

  policy_default_values = {
    log_analytics_workspace_id = jsonencode({ value = local.log_analytics_workspace_id })
    resource_group_location    = jsonencode({ value = local.location })
    email_security_contact     = jsonencode({ value = local.security_contact_email })
    allowed_locations          = jsonencode({ value = [local.location] })
  }

  policy_assignments_to_modify = {
    # The library disables every Defender plan but AI, which bills per token.
    (local.management_group_ids.root) = {
      policy_assignments = {
        Deploy-MDFC-Config-H224 = {
          parameters = {
            enableAscForAI = jsonencode({ value = "Disabled" })
          }
        }
      }
    }
    (local.management_group_ids.corp) = {
      policy_assignments = {
        Deploy-Private-DNS-Zones = {
          creation_enabled = length(local.private_dns_zones) > 0
          parameters = {
            for parameter, zone in local.private_dns_zones :
            parameter => jsonencode({ value = "${local.private_dns_zone_id_prefix}/${zone}" })
          }
        }
      }
    }
    (local.management_group_ids.online) = {
      policy_assignments = {
        Deny-HybridNetworking = {
          non_compliance_messages = [{
            message = "Online landing zones reach Azure over the internet, never over a gateway of their own."
          }]
        }
      }
    }
  }

  policy_role_assignments_dependencies = [module.log_analytics.resource_id]

  subscription_placement = {
    management = {
      subscription_id       = local.subscription_id
      management_group_name = local.management_group_ids.management
    }
    connectivity = {
      subscription_id       = local.connectivity.subscription_id
      management_group_name = local.management_group_ids.connectivity
    }
  }
}

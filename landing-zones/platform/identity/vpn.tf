# Custom audience application for the hub point-to-site gateway. The
# Microsoft-registered Azure VPN Client is shared by every tenant, so it cannot
# carry user assignments: pointing the gateway at an application of our own is
# what makes "only this group connects" expressible at all. The Azure VPN Client
# is pre-authorized against the scope, so users never see a consent prompt, and
# the enterprise application requires an assignment, so an account outside
# vpn_user_group_object_ids is refused before it reaches the gateway.
#
# Note what an assignment does and does not buy. It gets a user onto the
# network, and nothing more. Reaching a private endpoint still needs a firewall
# or NSG rule, and reading a secret still needs Azure RBAC on the Key Vault.
# Resolving the endpoint's name needs none of the three, which is why DNS is
# never the control.
module "vpn_app_registration" {
  source = "../../../modules/app-registration"

  name             = local.names.vpn_app_registration
  description      = "Custom audience for the hub point-to-site VPN gateway."
  sign_in_audience = "AzureADMyOrg"

  # "Assignment required" on the enterprise application.
  service_principal_app_role_assignment_required = true

  oauth2_permission_scopes = {
    p2s_vpn = {
      admin_consent_description  = "Connect to the hub point-to-site VPN gateway"
      admin_consent_display_name = "Connect to the P2S VPN"
      user_consent_description   = "Connect to the hub point-to-site VPN gateway"
      user_consent_display_name  = "Connect to the P2S VPN"
      value                      = "p2s-vpn"
      type                       = "Admin"
    }
  }

  pre_authorized_applications = {
    azure_vpn_client = {
      authorized_client_id = local.azure_vpn_client_app_id
      scope_keys           = ["p2s_vpn"]
    }
  }

  # An app role is how a group assignment is expressed declaratively. The
  # gateway never reads the role, it only cares that an assignment exists.
  app_roles = {
    vpn_user = {
      allowed_member_types = ["User"]
      description          = "Members may connect to the hub point-to-site VPN."
      display_name         = "VPN User"
      value                = "VpnUser"
    }
  }

  app_role_assignments = {
    for group_object_id in local.vpn_user_group_object_ids : group_object_id => {
      app_role_key        = "vpn_user"
      principal_object_id = group_object_id
    }
  }
}

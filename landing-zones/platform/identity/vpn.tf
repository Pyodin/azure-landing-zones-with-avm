# Custom audience for the hub point-to-site gateway, so access can be limited
# to assigned users.
module "vpn_app_registration" {
  # Pinned to a commit: the module carries no tags yet.
  source = "git::https://github.com/Pyodin/terraform-azurerm-avm-res-aad-appregistration.git?ref=f783f57a75052d3c609c9c31437abbcce1f4b56a"

  name             = local.names.vpn_app_registration
  description      = "Custom audience for the hub point-to-site VPN gateway."
  sign_in_audience = "AzureADMyOrg"

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

  app_roles = {
    vpn_user = {
      allowed_member_types = ["User"]
      description          = "Members may connect to the hub point-to-site VPN."
      display_name         = "VPN User"
      value                = "VpnUser"
    }
  }

  # Groups are assigned by hand: AppRoleAssignment.ReadWrite.All would let CI
  # grant itself any Graph role.
}

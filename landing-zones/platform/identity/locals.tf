locals {
  location_short = "weu"
  environment    = "prod"
  instance       = "001"

  # Microsoft-registered Azure VPN Client application. It is pre-authorized
  # against the custom audience below rather than used as the audience itself,
  # because an application Microsoft owns carries no assignments and so would
  # let every account in the tenant connect.
  # https://learn.microsoft.com/azure/vpn-gateway/point-to-site-entra-register-custom-app
  azure_vpn_client_app_id = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"

  # Entra ID groups whose direct members may connect to the point-to-site VPN.
  # Nested groups are not supported. Empty is a working configuration in which
  # nobody connects: the enterprise application requires an assignment, so an
  # unassigned account is refused at sign-in.
  vpn_user_group_object_ids = []

  suffix = "${local.environment}-${local.location_short}-${local.instance}"

  names = {
    vpn_app_registration = "app-vpn-hub-${local.suffix}"
  }
}

locals {
  location_short = "frc"
  environment    = "prod"
  instance       = "001"

  # Microsoft-owned Azure VPN Client, pre-authorized on the custom audience.
  azure_vpn_client_app_id = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"

  suffix = "${local.environment}-${local.location_short}-${local.instance}"

  names = {
    vpn_app_registration = "app-vpn-hub-${local.suffix}"
  }
}

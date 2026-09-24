# A warning rather than a precondition, so the hub still applies on its own.
check "vpn_audience_is_tenant_owned" {
  assert {
    condition     = !local.deploy_vpn || local.identity.vpn_audience_client_id != "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"
    error_message = "The VPN gateway uses the Microsoft-owned Azure VPN Client as its audience, so every account in the tenant can connect. Deploy platform/identity and copy its vpn_audience_client_id output into local.identity."
  }
}

output "vpn_audience_client_id" {
  description = "Custom audience the Azure VPN Client authenticates against. Copy into the connectivity landing zone locals."
  value       = module.vpn_app_registration.client_id
}

output "vpn_enterprise_application_object_id" {
  description = "Enterprise application to assign the VPN user groups to, by hand."
  value       = module.vpn_app_registration.service_principal_object_id
}

# Mirrors the "identity" block in the connectivity landing zone locals.
output "connectivity_inputs" {
  description = "Values to copy into the connectivity landing zone locals."
  value = {
    vpn_audience_client_id = module.vpn_app_registration.client_id
  }
}

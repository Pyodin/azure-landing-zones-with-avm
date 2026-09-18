# Everything this landing zone consumes from the platform/management landing
# zone. Read through data sources, never through a remote state backend, so the
# two teams never share a state file.
data "azurerm_log_analytics_workspace" "platform" {
  provider = azurerm.platform

  name                = local.platform.log_analytics_workspace_name
  resource_group_name = local.platform.management_resource_group
}

# The private DNS initiative assigned in the management landing zone remediates
# into the zones this landing zone owns. The grant is written here, by the team
# that owns the zones, rather than by the team that owns the policy: the same
# separation that keeps a workload team from ever holding write access on the
# hub DNS resource group.
resource "azurerm_role_assignment" "private_dns_policy" {
  count = local.platform.private_dns_policy_principal_id == "" ? 0 : 1

  scope                = module.resource_group_dns.resource_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = local.platform.private_dns_policy_principal_id
  principal_type       = "ServicePrincipal"
}

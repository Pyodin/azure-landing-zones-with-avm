locals {
  # Every management group by key, so an assignment scope is one lookup rather
  # than a guess about which tier a group sits in.
  management_group_ids = merge(
    {
      (local.management_group_prefix) = azurerm_management_group.intermediate_root.id
    },
    {
      for key, mg in azurerm_management_group.tier1 : key => mg.id
    },
    {
      for key, mg in azurerm_management_group.tier2 : key => mg.id
    },
  )

  # Zone resource IDs are composed from names rather than read through a data
  # source, so this landing zone can be deployed and governed on its own
  # schedule. It is the same trade the hub makes when it writes firewall rules
  # against spoke prefixes declared in its own locals.
  private_dns_zone_id_prefix = join("/", [
    "/subscriptions/${local.subscriptions.connectivity}",
    "resourceGroups/${local.connectivity.dns_resource_group_name}",
    "providers/Microsoft.Network/privateDnsZones",
  ])

  # The subset of the ALZ Deploy-Private-DNS-Zones initiative that matches the
  # zones the hub actually hosts. Each one is a built-in DeployIfNotExists that
  # attaches a private DNS zone group to a private endpoint as it is created, so
  # a workload subscription never needs write access to the hub DNS resource
  # group, and an endpoint created outside Terraform still resolves.
  #
  # DeployIfNotExists evaluates on create and update. Endpoints that already
  # exist need a remediation task before the policy touches them.
  #
  # There is no built-in for PostgreSQL flexible server. It is absent from the
  # ALZ initiative and from the built-in definitions altogether, so that one
  # needs a custom definition or its zone group kept in Terraform.
  private_dns_policies = {
    key_vault = {
      reference_id  = "DINE-Private-DNS-Azure-KeyVault"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ac673a9a-f77d-4846-b2d8-a57f8e1c01d4"
      zone_name     = "privatelink.vaultcore.azure.net"
    }
    container_registry = {
      reference_id  = "DINE-Private-DNS-Azure-ACR"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e9585a95-5b8c-4d03-b193-dc7eb5ac4c32"
      zone_name     = "privatelink.azurecr.io"
    }
    storage_blob = {
      reference_id  = "DINE-Private-DNS-Azure-Storage-Blob"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/75973700-529f-4de2-b794-fb9b6781b6b0"
      zone_name     = "privatelink.blob.core.windows.net"
    }
  }

  # Deny only, on purpose. A guardrail that refuses the deployment shows up in
  # the plan and needs no identity, no remediation task and no standing
  # permission on the subscriptions it governs. Everything this repository
  # deploys already satisfies every one of these, so the baseline holds a line
  # rather than announcing a backlog.
  baseline_policies = {
    allowed_locations = {
      reference_id  = "Deny-Location"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
      parameter_values = {
        listOfAllowedLocations = { value = [local.location] }
        effect                 = { value = "Deny" }
      }
    }

    # This one has no effect parameter. The built-in denies outright.
    public_ip_on_nic = {
      reference_id     = "Deny-PublicIP-On-NIC"
      definition_id    = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
      parameter_values = {}
    }
    key_vault_public_access = {
      reference_id  = "Deny-KeyVault-Public-Access"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/405c5871-3e91-4644-8a63-58e19d68ff5b"
      parameter_values = {
        effect = { value = "Deny" }
      }
    }
    storage_public_access = {
      reference_id  = "Deny-Storage-Public-Access"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"
      parameter_values = {
        effect = { value = "Deny" }
      }
    }
    registry_public_access = {
      reference_id  = "Deny-ACR-Public-Access"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0fdf0491-d080-4575-b627-ad0e843cba0f"
      parameter_values = {
        effect = { value = "Deny" }
      }
    }
    aks_private_cluster = {
      reference_id  = "Deny-AKS-Public-API"
      definition_id = "/providers/Microsoft.Authorization/policyDefinitions/040732e8-d947-40b8-95d6-854c95024bf8"
      parameter_values = {
        effect = { value = "Deny" }
      }
    }
  }
}

resource "azurerm_management_group_policy_set_definition" "private_dns_zones" {
  name                = local.names.private_dns_policy
  policy_type         = "Custom"
  display_name        = "Configure Azure PaaS services to use private DNS zones"
  description         = "Ensures private endpoints to Azure PaaS services are integrated with the private DNS zones hosted in the connectivity landing zone."
  management_group_id = azurerm_management_group.intermediate_root.id
  metadata            = jsonencode({ category = "Network" })

  dynamic "policy_definition_reference" {
    for_each = local.private_dns_policies

    content {
      reference_id         = policy_definition_reference.value.reference_id
      policy_definition_id = policy_definition_reference.value.definition_id

      parameter_values = jsonencode({
        privateDnsZoneId = {
          value = "${local.private_dns_zone_id_prefix}/${policy_definition_reference.value.zone_name}"
        }
      })
    }
  }
}

resource "azurerm_management_group_policy_set_definition" "baseline" {
  name                = "Enforce-Landing-Zone-Baseline"
  policy_type         = "Custom"
  display_name        = "Landing zone baseline"
  description         = "Refuses the deployments a landing zone is not allowed to make: outside the approved region, with a public IP on a network interface, or with a PaaS data plane open to the internet."
  management_group_id = azurerm_management_group.intermediate_root.id
  metadata            = jsonencode({ category = "Security" })

  dynamic "policy_definition_reference" {
    for_each = local.baseline_policies

    content {
      reference_id         = policy_definition_reference.value.reference_id
      policy_definition_id = policy_definition_reference.value.definition_id
      parameter_values     = jsonencode(policy_definition_reference.value.parameter_values)
    }
  }
}

resource "azurerm_management_group_policy_assignment" "baseline" {
  name                 = local.names.baseline_policy
  display_name         = "Landing zone baseline"
  description          = "Assigned at the intermediate root, so a new landing zone inherits it the day its subscription is placed."
  management_group_id  = local.management_group_ids[local.baseline_assignment_scope]
  policy_definition_id = azurerm_management_group_policy_set_definition.baseline.id

  non_compliance_message {
    content = "This deployment is refused by the landing zone baseline. Check the region, public IP addresses on network interfaces, and public network access on PaaS resources."
  }
}

resource "azurerm_management_group_policy_assignment" "private_dns_zones" {
  name                 = local.names.private_dns_policy
  display_name         = "Configure Azure PaaS services to use private DNS zones"
  description          = "Private endpoints resolve through the zones in ${local.connectivity.dns_resource_group_name}."
  management_group_id  = local.management_group_ids[local.private_dns_assignment_scope]
  policy_definition_id = azurerm_management_group_policy_set_definition.private_dns_zones.id
  location             = local.location

  identity {
    type = "SystemAssigned"
  }

  non_compliance_message {
    content = "Private endpoints must use the private DNS zones hosted in the connectivity landing zone."
  }
}

# The remediation writes a privateDnsZoneGroup on the private endpoint, which
# lives in a workload subscription under this management group. The other half
# of the job, writing the record into the zone, is granted by the connectivity
# landing zone that owns the zones: paste private_dns_policy_principal_id into
# its locals. Splitting the grant keeps each team granting access to what it
# owns, and keeps this landing zone deployable before the hub exists.
resource "azurerm_role_assignment" "private_dns_policy_endpoints" {
  scope                = local.management_group_ids[local.private_dns_assignment_scope]
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_management_group_policy_assignment.private_dns_zones.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

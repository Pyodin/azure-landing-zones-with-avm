locals {
  # The state account lives here. A landing zone deploys elsewhere and is told this
  # explicitly, because the backend does not follow ARM_SUBSCRIPTION_ID.
  subscription_id = "535e631d-1f74-4fd4-b38e-fbd577b8c817"

  location       = "francecentral"
  location_short = "frc"
  environment    = "prod"
  instance       = "001"

  enable_telemetry = false

  retention_days = 30

  # A container is an RBAC boundary: a team can be granted its own state and nothing else.
  landing_zones = [
    "platform/management",
    "platform/identity",
    "platform/connectivity",
    "application/workload-aks",
  ]

  github_repository = "Pyodin/azure-landing-zones-with-avm"

  # A federated credential matches one GitHub subject. That is what separates the
  # two identities: only a job declaring the production environment can obtain the
  # one that writes.
  cicd_plan_subjects = {
    main         = "ref:refs/heads/main"
    pull_request = "pull_request"
  }

  cicd_apply_subjects = {
    production = "environment:production"
  }

  cicd_plan_graph_app_roles = {
    application_read = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
  }

  cicd_apply_graph_app_roles = {
    application_readwrite_ownedby = "18a4783c-866b-4cc7-a460-3d5e5662c884"
  }

  suffix = "${local.environment}-${local.location_short}-${local.instance}"
  unique = substr(local.subscription_id, 0, 4)

  names = {
    resource_group  = "rg-tfstate-${local.suffix}"
    storage_account = "sttfstate${local.environment}${local.location_short}${local.instance}${local.unique}"
    cicd_plan       = "id-cicd-plan-${local.suffix}"
    cicd_apply      = "id-cicd-apply-${local.suffix}"
  }

  tags = {
    Environment = local.environment
    Workload    = "tfstate"
    LandingZone = "platform"
    ManagedBy   = "Terraform"
    Repository  = "AzLandingZones"
  }
}

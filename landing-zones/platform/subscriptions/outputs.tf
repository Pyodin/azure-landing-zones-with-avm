output "budget_resource_ids" {
  description = "Monthly budget per subscription."
  value       = { for key, subscription in module.subscription : key => subscription.budget_resource_id }
}

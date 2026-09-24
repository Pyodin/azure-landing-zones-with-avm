output "key_vault_uri" {
  description = "Key Vault URI, resolvable to a private address over the VPN."
  value       = module.key_vault.uri
}

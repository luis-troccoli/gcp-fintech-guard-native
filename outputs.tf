# Root-level outputs
output "network_module_outputs" {
  description = "Outputs from the network module"
  value       = module.network
}

output "security_module_outputs" {
  description = "Outputs from the security module"
  value       = module.security
}

output "finops_module_outputs" {
  description = "Outputs from the finops module"
  value       = module.finops
}

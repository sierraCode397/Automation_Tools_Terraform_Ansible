output "security_group_id" {
  description = "The ID of the created security group"
  value       = module.security_group.this_security_group_id
}

output "security_group_ids" {
  description = "A list of security group IDs"
  value       = module.security_group.this_security_group_ids
}

output "private_ips" {
  description = "Private IPv4 addresses of Frontend and Backend instances"
  value = {
    Frontend = module.ec2_instance["Frontend"].private_ip
    Backend  = module.ec2_instance["Backend"].private_ip
  }
}

output "public_dns" {
  description = "Public DNS names of Frontend and Bastion instances"
  value = {
    Frontend = module.ec2_instance["Frontend"].public_dns
    Bastion  = module.ec2_instance["Bastion"].public_dns
  }
}

/* 
output "rds_master_password_secret_arn" {
  value     = module.db.master_user_secret[0].secret_arn
  sensitive = true 
} */
/* terraform output rds_master_password_secret_arn */
/* aws secretsmanager get-secret-value --secret-id <SECRET_ARN> */
# Default

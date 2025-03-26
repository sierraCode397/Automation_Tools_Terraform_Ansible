output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.db.db_instance_availability_zone
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.db.db_instance_engine
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database"
  value       = module.db.db_instance_engine_version_actual
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = module.db.db_instance_hosted_zone_id
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.db.db_instance_identifier
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.db.db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.db.db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = module.db.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db.db_instance_port
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.db.db_subnet_group_id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = module.db.db_subnet_group_arn
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = module.db.db_parameter_group_id
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = module.db.db_parameter_group_arn
}

output "db_enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the monitoring role"
  value       = module.db.enhanced_monitoring_iam_role_arn
}

output "db_instance_cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes"
  value       = module.db.db_instance_cloudwatch_log_groups
}

output "db_instance_master_user_secret_arn" {
  description = "The ARN of the master user secret (Only available when manage_master_user_password is set to true)"
  value       = module.db.db_instance_master_user_secret_arn
}

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

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db.db_instance_endpoint
}

output "rds_endpoint" {
  description = "The endpoint of the RDS MySQL instance"
  value       = module.db.this_db_instance_endpoint
}

output "load_balancer_dns" {
  value = aws_lb.application-lb.dns_name
  description = "The DNS name of the Load Balancer"
}

/* 
output "rds_master_password_secret_arn" {
  value     = module.db.master_user_secret[0].secret_arn
  sensitive = true 
} */
/* terraform output rds_master_password_secret_arn */
/* aws secretsmanager get-secret-value --secret-id <SECRET_ARN> */
# Default

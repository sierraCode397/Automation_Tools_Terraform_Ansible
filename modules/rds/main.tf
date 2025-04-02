# modules/rds/main.tf

module "db" {
  source = "terraform-aws-modules/rds/aws"
  
  identifier = var.identifier

  engine               = var.engine
  engine_version       = var.engine_version
  family              = var.family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name              = var.db_name
  username             = var.username
  password             = var.password
  manage_master_user_password = false
  port                 = var.port

  multi_az             = var.multi_az
  db_subnet_group_name = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids

  maintenance_window              = var.maintenance_window
  backup_window                   = var.backup_window
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  create_cloudwatch_log_group     = var.create_cloudwatch_log_group

  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  parameters = var.parameters

  tags = var.tags
  db_instance_tags = var.db_instance_tags
  db_option_group_tags = var.db_option_group_tags
  db_parameter_group_tags = var.db_parameter_group_tags
  db_subnet_group_tags = var.db_subnet_group_tags
  cloudwatch_log_group_tags = var.cloudwatch_log_group_tags

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id
}

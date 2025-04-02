variable "identifier" {
  description = "The database identifier"
  type        = string
  default     = "complete-mysql"
}

variable "name" {
  description = "The name of the RDS instance"
  type        = string
}

variable "engine" {
  description = "The database engine"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "8.0"
}

variable "family" {
  description = "The database family"
  type        = string
  default     = "mysql8.0"
}

variable "major_engine_version" {
  description = "The major version of the database engine"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for the RDS instance"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for the RDS instance"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "The database name"
  type        = string
  default     = "completeMysql"
}

variable "username" {
  description = "The username for the database"
  type        = string
}

variable "password" {
  description = "The password for the database"
  type        = string
}

variable "port" {
  description = "The port on which the database listens"
  type        = number
  default     = 3306
}

variable "multi_az" {
  description = "Whether to deploy the RDS instance in multiple availability zones"
  type        = bool
  default     = false
}

variable "db_subnet_group_name" {
  description = "The subnet group name for the RDS instance"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs associated with the RDS instance"
  type        = list(string)
}

variable "maintenance_window" {
  description = "The maintenance window for the RDS instance"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  description = "The backup window for the RDS instance"
  type        = string
  default     = "03:00-06:00"
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["general"]
}

variable "create_cloudwatch_log_group" {
  description = "Whether to create a CloudWatch Log Group"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS instance"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the RDS instance"
  type        = bool
  default     = false
}

variable "parameters" {
  description = "List of parameters to set for the database"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to the RDS instance"
  type        = map(string)
}

variable "db_instance_tags" {
  description = "Tags specific to the RDS instance"
  type        = map(string)
}

variable "db_option_group_tags" {
  description = "Tags specific to the DB option group"
  type        = map(string)
}

variable "db_parameter_group_tags" {
  description = "Tags specific to the DB parameter group"
  type        = map(string)
}

variable "db_subnet_group_tags" {
  description = "Tags specific to the DB subnet group"
  type        = map(string)
}

variable "cloudwatch_log_group_tags" {
  description = "Tags specific to the CloudWatch log group"
  type        = map(string)
}

variable "storage_encrypted" {
  description = "Whether to enable storage encryption for the RDS instance"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS Key ID for encryption"
  type        = string
  default     = null
}

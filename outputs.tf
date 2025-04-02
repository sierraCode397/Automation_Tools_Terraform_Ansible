/* 
output "rds_master_password_secret_arn" {
  value     = module.db.master_user_secret[0].secret_arn
  sensitive = true 
} */
/* terraform output rds_master_password_secret_arn */
/* aws secretsmanager get-secret-value --secret-id <SECRET_ARN> */
# Default

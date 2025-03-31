# modules/load_balancer/variables.tf

variable "name" {
  description = "The name of the Load Balancer"
  type        = string
}

variable "security_groups" {
  description = "List of security group IDs associated with the Load Balancer"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnet IDs where the Load Balancer should be created"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection for the Load Balancer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the Load Balancer"
  type        = map(string)
}

variable "target_group_name" {
  description = "Name of the Target Group"
  type        = string
}

variable "target_group_port" {
  description = "Port of the Target Group"
  type        = number
}

variable "target_group_protocol" {
  description = "Protocol used by the Target Group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Load Balancer and Target Group will be created"
  type        = string
}

variable "listener_port" {
  description = "Port for the HTTP Listener"
  type        = number
}

variable "listener_protocol" {
  description = "Protocol for the Listener (usually HTTP)"
  type        = string
}

variable "target_id" {
  description = "ID of the EC2 instance to attach to the Target Group"
  type        = string
}

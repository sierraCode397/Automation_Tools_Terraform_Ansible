variable "key_name" {
  description = "The name of the key pair"
  type        = string
}

variable "public_key_path" {
  description = "Path to the public key for SSH access"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type for EC2"
  type        = string
  default     = "t2.micro"
}

variable "security_groups" {
  description = "Security groups for instances"
  type        = map(list(string))
}

variable "subnets" {
  description = "Subnets for different instances"
  type        = map(string)
}

variable "tags" {
  description = "Tags for the instances"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}
variable "name" {
  description = "Name for the security group"
  type        = string
}

variable "description" {
  description = "Description for the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "ingress_with_cidr_blocks" {
  description = "List of ingress rules with CIDR blocks"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
    cidr_blocks = string
  }))
}

variable "egress_with_cidr_blocks" {
  description = "List of egress rules with CIDR blocks"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
    cidr_blocks = string
  }))
}

variable "tags" {
  description = "Tags to apply to the security group"
  type        = map(string)
}

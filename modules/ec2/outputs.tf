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

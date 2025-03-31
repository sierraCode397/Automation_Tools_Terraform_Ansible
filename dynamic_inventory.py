#!/usr/bin/env python3

import boto3
import argparse
import json

def get_aws_instances(region):
    ec2 = boto3.resource('ec2', region_name=region)
    instances = ec2.instances.filter(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

    hosts = {}
    for instance in instances:
        public_ip = instance.public_ip_address
        if public_ip:  # Only add instances with public IPs
            instance_name = next((tag['Value'] for tag in instance.tags if tag['Key'] == 'Name'), instance.id)
            hosts[instance_name] = {
                "instance_id": instance.id,
                "ansible_user": "ubuntu",  # You can change this to 'vagrant' or another user if needed
                "ansible_host": public_ip,
                "ansible_ssh_private_key_file": "~/.ssh/user1.pem",  # Adjust the path to your SSH key
                "ansible_port": "22",  # Default port for SSH, change if needed
                "image_id": instance.image_id
            }

    return hosts

def get_inventory(region):
    instances = get_aws_instances(region)
    
    inventory = {
        "all": {
            "hosts": list(instances.keys()),
        },
        "_meta": {
            "hostvars": {}
        },
        "image_ids": {
            "ansible_user": list(instances.keys())
        }
    }
    
    for instance_name, instance in instances.items():
        inventory["_meta"]["hostvars"][instance_name] = instance
        inventory["_meta"]["hostvars"][instance_name]["ansible_host"] = instance["ansible_host"]
        inventory["image_ids"][instance_name] = {
            "image_id": instance["image_id"],  # Add only the image_id for each instance
            "Distribution": instance["ansible_user"]
        }

    return inventory

def parse_args():
    parser = argparse.ArgumentParser(description="Ansible Dynamic Inventory Script")
    parser.add_argument('--list', action='store_true', help="List inventory")
    parser.add_argument('--host', type=str, help="Get details for a specific host")
    return parser.parse_args()

def generate_inventory():
    region = 'us-east-1'  # Update to the desired region
    instances = get_aws_instances(region)

    if args.list:
        inventory = get_inventory(region)
        print(json.dumps(inventory, indent=2))

    if args.host:
        if args.host in instances:
            print(json.dumps(instances[args.host], indent=2))
        else:
            print(f"Host {args.host} not found in inventory.")

if __name__ == '__main__':
    args = parse_args()
    generate_inventory()
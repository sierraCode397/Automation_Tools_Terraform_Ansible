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
        if public_ip:
            instance_name = next(
                (tag['Value'] for tag in instance.tags if tag['Key'] == 'Name'),
                instance.id
            )
            hosts[instance_name] = {
                "instance_id": instance.id,
                "ansible_user": "ubuntu",
                "ansible_host": public_ip,
                "ansible_ssh_private_key_file": "~/.ssh/user1.pem",
                "ansible_port": "22",
                "image_id": instance.image_id
            }
    return hosts

def get_rds_instances(region):
    rds_client = boto3.client('rds', region_name=region)
    response = rds_client.describe_db_instances()
    rds_instances = {}
    for db in response['DBInstances']:
        identifier = db['DBInstanceIdentifier']
        endpoint = db.get('Endpoint', {}).get('Address', '')
        if endpoint:
            rds_instances[identifier] = {
                "rds_endpoint": endpoint,
                "rds_port": db.get('Endpoint', {}).get('Port', '')
            }
    return rds_instances

def get_alb_instances(region):
    elbv2 = boto3.client('elbv2', region_name=region)
    response = elbv2.describe_load_balancers()
    alb_instances = {}
    for lb in response['LoadBalancers']:
        name = lb['LoadBalancerName']
        dns = lb.get('DNSName', '')
        if dns:
            alb_instances[name] = {
                "load_balancer_dns": dns,
                "load_balancer_name": lb.get('LoadBalancerName', ''),
                "type": lb.get('Type', '')
            }
    return alb_instances

def get_inventory(region):
    ec2_instances = get_aws_instances(region)
    rds_instances = get_rds_instances(region)
    alb_instances = get_alb_instances(region)
    
    inventory = {
        "all": {
            "children": ["ec2", "rds", "alb"]
        },
        "ec2": {
            "hosts": list(ec2_instances.keys())
        },
        "rds": {
            "hosts": list(rds_instances.keys())
        },
        "alb": {
            "hosts": list(alb_instances.keys())
        },
        "_meta": {
            "hostvars": {}
        }
    }
    
    # Add host variables for each group
    for name, host in ec2_instances.items():
        inventory["_meta"]["hostvars"][name] = host
    for name, host in rds_instances.items():
        inventory["_meta"]["hostvars"][name] = host
    for name, host in alb_instances.items():
        inventory["_meta"]["hostvars"][name] = host

    return inventory

def parse_args():
    parser = argparse.ArgumentParser(description="Ansible Dynamic Inventory Script")
    parser.add_argument('--list', action='store_true', help="List inventory")
    parser.add_argument('--host', type=str, help="Get details for a specific host")
    return parser.parse_args()

def generate_inventory():
    region = 'us-east-1'
    
    if args.list:
        inventory = get_inventory(region)
        print(json.dumps(inventory, indent=2))
    elif args.host:
        # Merge all hosts from ec2, rds, and alb
        ec2_instances = get_aws_instances(region)
        rds_instances = get_rds_instances(region)
        alb_instances = get_alb_instances(region)
        all_hosts = {**ec2_instances, **rds_instances, **alb_instances}
        if args.host in all_hosts:
            print(json.dumps(all_hosts[args.host], indent=2))
        else:
            print(f"Host {args.host} not found in inventory.")
    else:
        print("Specify --list or --host <hostname>.")

if __name__ == '__main__':
    args = parse_args()
    generate_inventory()
    
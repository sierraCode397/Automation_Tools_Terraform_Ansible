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
        ip_address = public_ip if public_ip else instance.private_ip_address
        public_dns = instance.public_dns_name if public_ip else ""
        if ip_address:
            instance_name = f"{region}-{next((tag['Value'] for tag in instance.tags if tag['Key'] == 'Name'), instance.id)}"
            hosts[instance_name] = {
                "instance_id": instance.id,
                "ansible_user": "ubuntu",
                "ansible_host": ip_address,
                "ansible_ssh_private_key_file": "~/.ssh/user1.pem",
                "ansible_port": "22",
                "ansible_dns": public_dns,
                "image_id": instance.image_id
            }
    return hosts

def get_rds_instances(region):
    rds_client = boto3.client('rds', region_name=region)
    response = rds_client.describe_db_instances()
    rds_instances = {}
    for db in response['DBInstances']:
        identifier = f"{region}-{db['DBInstanceIdentifier']}"
        endpoint = db.get('Endpoint', {}).get('Address', '')
        if endpoint:
            rds_instances[identifier] = {
                "rds_endpoint": endpoint,
                "rds_port": db.get('Endpoint', {}).get('Port', ''),
                "region": region
            }
    return rds_instances

def get_alb_instances(region):
    elbv2 = boto3.client('elbv2', region_name=region)
    response = elbv2.describe_load_balancers()
    alb_instances = {}
    for lb in response['LoadBalancers']:
        name = f"{region}-{lb['LoadBalancerName']}"
        dns = lb.get('DNSName', '')
        if dns:
            alb_instances[name] = {
                "load_balancer_dns": dns,
                "load_balancer_name": lb.get('LoadBalancerName', ''),
                "type": lb.get('Type', ''),
                "region": region
            }
    return alb_instances

def get_inventory(regions):
    all_ec2 = {}
    all_rds = {}
    all_alb = {}

    for region in regions:
        all_ec2.update(get_aws_instances(region))
        all_rds.update(get_rds_instances(region))
        all_alb.update(get_alb_instances(region))
    
    inventory = {
        "all": {
            "children": ["ec2", "rds", "alb"]
        },
        "ec2": {
            "hosts": list(all_ec2.keys())
        },
        "rds": {
            "hosts": list(all_rds.keys())
        },
        "alb": {
            "hosts": list(all_alb.keys())
        },
        "_meta": {
            "hostvars": {}
        }
    }
    
    # Add host variables for each group
    for name, host in {**all_ec2, **all_rds, **all_alb}.items():
        inventory["_meta"]["hostvars"][name] = host

    return inventory

"""  """

def extract_env_values(inventory):
    """Extract the first available load_balancer_dns and rds_endpoint from the inventory."""
    load_balancer_dns = None
    rds_endpoint = None

    for host, vars in inventory["_meta"]["hostvars"].items():
        if not load_balancer_dns and "load_balancer_dns" in vars:
            load_balancer_dns = vars["load_balancer_dns"]
        if not rds_endpoint and "rds_endpoint" in vars:
            rds_endpoint = vars["rds_endpoint"]
        # If both values are found, we can stop early
        if load_balancer_dns and rds_endpoint:
            break

    return load_balancer_dns, rds_endpoint

def write_env_file(load_balancer_dns, rds_endpoint, filename="env_vars.sh"):
    """Write the export commands to a shell file."""
    with open(filename, "w") as f:
        f.write("#!/bin/bash\n")
        if load_balancer_dns:
            f.write(f'export LOAD_BALANCER_DNS="{load_balancer_dns}"\n')
        else:
            f.write('# No load_balancer_dns found\n')
        if rds_endpoint:
            f.write(f'export RDS_ENDPOINT="{rds_endpoint}"\n')
        else:
            f.write('# No rds_endpoint found\n')
    print(f"Environment variables written to {filename}. To load them, run:\nsource {filename}")

"""  source env_vars.sh """

def parse_args():
    parser = argparse.ArgumentParser(description="Ansible Dynamic Inventory Script")
    parser.add_argument('--list', action='store_true', help="List inventory")
    parser.add_argument('--host', type=str, help="Get details for a specific host")
    parser.add_argument('--regions', nargs='+', default=['us-east-1'],
                        help="List of AWS regions to query (default: ['us-east-1'])")
    # New argument to trigger environment variable export:
    parser.add_argument('--set-env', action='store_true', help="Extract and write environment variables")
    return parser.parse_args()

def generate_inventory():
    regions = args.regions  # List of regions passed as command-line arguments

    if args.list:
        inventory = get_inventory(regions)
        print(json.dumps(inventory, indent=2))
    elif args.host:
        # Merge all hosts from each service
        all_hosts = {}
        for region in regions:
            all_hosts.update(get_aws_instances(region))
            all_hosts.update(get_rds_instances(region))
            all_hosts.update(get_alb_instances(region))
        if args.host in all_hosts:
            print(json.dumps(all_hosts[args.host], indent=2))
        else:
            # Return empty JSON if host not found (for Ansible)
            print(json.dumps({}))
    elif args.set_env:
        # Extract the desired environment values from the merged inventory.
        inventory = get_inventory(regions)
        load_balancer_dns, rds_endpoint = extract_env_values(inventory)
        write_env_file(load_balancer_dns, rds_endpoint)
    else:
        print("Specify --list or --host <hostname>.")

if __name__ == '__main__':
    args = parse_args()
    generate_inventory()
    
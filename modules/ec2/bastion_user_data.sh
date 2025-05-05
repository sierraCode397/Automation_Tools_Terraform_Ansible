#!/bin/bash
exec > /var/log/user-data.log 2>&1 
set -eux  # Debug mode: stop on error and print each command

cat <<EOF > /home/ubuntu/COMMANDS.txt

------- LOCAL

sudo chmod +x /home/ubuntu/managed_nodes.py

export TF_VAR_db_password="AdminAdmin123"
export AWS_SECRET_ACCESS_KEY=
export AWS_ACCESS_KEY_ID=

ansible-playbook -i managed_nodes.py setting_bastion.yml --limit us-east-1-Bastion -e "ansible_python_interpreter=/usr/bin/python3"

-------REMOTE

python3 ./managed_nodes.py --list

python3 managed_nodes.py --set-env

source env_vars.sh

echo LOAD_BALANCER_DNS
echo RDS_ENDPOINT'

ansible ec2 -i managed_nodes.py -m ping -e "ansible_python_interpreter=/usr/bin/python3"

ansible-playbook -i managed_nodes.py backend.yml --limit us-east-1-Backend -e "ansible_python_interpreter=/usr/bin/python3"

ansible-playbook -i managed_nodes.py frontend.yml --limit us-east-1-Frontend -e "ansible_python_interpreter=/usr/bin/python3"

EOF

cat <<EOF > /home/ubuntu/managed_nodes.py
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

""" source env_vars.sh """

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

EOF

sudo chmod +x /home/ubuntu/managed_nodes.py

cat <<EOF > /home/ubuntu/frontend.yml
---
- name: Setup Frontend Application
  hosts: all
  become: true
  tasks:

    - name: Update apt repository
      apt:
        update_cache: yes

    - name: Install curl
      apt:
        name: curl
        state: present

    - name: Install Node.js (LTS version)
      shell: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
      args:
        creates: /usr/bin/node  # Prevents reinstallation if already installed

    - name: Install Git
      apt:
        name: git
        state: present

    - name: Clone the repository
      git:
        repo: 'https://github.com/aljoveza/devops-rampup.git'
        dest: '/home/ubuntu/devops-rampup'
        version: master
        force: yes


    - name: Install npm dependencies
      npm:
        path: /home/ubuntu/devops-rampup/movie-analyst-ui
        state: present

    - name: Install dotenv
      npm:
        path: /home/ubuntu/devops-rampup/movie-analyst-ui
        name: dotenv
        state: present

    - name: Create .env file with environment variables
      copy:
        content: |
          PORT=3030
          BACKEND_URL={{ lookup('env', 'LOAD_BALANCER_DNS') }}
        dest: /home/ubuntu/devops-rampup/movie-analyst-ui/.env
        owner: ubuntu
        group: ubuntu
        mode: '0644'

    - name: Insert dotenv config line at the top of server.js
      lineinfile:
        path: /home/ubuntu/devops-rampup/movie-analyst-ui/server.js
        line: "require('dotenv').config();"
        insertbefore: BOF

    - name: Run server.js in detached mode
      shell: nohup npm start > output.log 2>&1 &
      args:
        chdir: /home/ubuntu/devops-rampup/movie-analyst-ui
      become: true

EOF

cat <<EOF > /home/ubuntu/backend.yml
---
- name: Setup Backend Application
  hosts: all
  become: true
  tasks:

    - name: Update apt repository
      apt:
        update_cache: yes

    - name: Install curl
      apt:
        name: curl
        state: present

    - name: Install Node.js (LTS version)
      shell: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs
      args:
        creates: /usr/bin/node  # Prevents reinstallation if already installed

    - name: Install Git
      apt:
        name: git
        state: present

    - name: Clone the repository
      git:
        repo: 'https://github.com/aljoveza/devops-rampup.git'
        dest: '/home/ubuntu/devops-rampup'
        version: master
        force: yes

    - name: List contents of the movie-analyst-api directory
      command: ls -l /home/ubuntu/devops-rampup/movie-analyst-api

    - name: Install npm dependencies
      npm:
        path: /home/ubuntu/devops-rampup/movie-analyst-api
        state: present

    - name: Install dotenv
      command: sudo npm install dotenv
      args:
        chdir: /home/ubuntu/devops-rampup/movie-analyst-api

    - name: Create .env file with environment variables
      copy:
        content: |
          PORT=3000
          DB_HOST={{ lookup('env','RDS_ENDPOINT') }}
          DB_USER=admin
          DB_PASS=AdminAdmin123
          DB_NAME=movie_db
          NODE_ENV=dev
        dest: /home/ubuntu/devops-rampup/movie-analyst-api/.env
        owner: ubuntu
        group: ubuntu
        mode: '0644'

    - name: Install MariaDB client
      apt:
        name: mariadb-client-core
        state: present

    - name: Install MySQL client
      apt:
        name: mysql-client-core-8.0
        state: present

    - name: Create the database and tables on RDS
      shell: |
        mysql -h {{ lookup('env','RDS_ENDPOINT') }} -u admin -pAdminAdmin123 --connect-timeout=30 -e "
          CREATE DATABASE IF NOT EXISTS movie_db;

          USE movie_db;

          CREATE TABLE IF NOT EXISTS publications (
              name VARCHAR(250) PRIMARY KEY,
              avatar VARCHAR(250)
          );
          CREATE TABLE IF NOT EXISTS reviewers (
              name VARCHAR(255) PRIMARY KEY,
              publication VARCHAR(250),
              avatar VARCHAR(250),
              FOREIGN KEY (publication) REFERENCES publications(name) ON DELETE CASCADE
          );
          CREATE TABLE IF NOT EXISTS movies (
              title VARCHAR(250),
              release_year VARCHAR(250),
              score INT(11),
              reviewer VARCHAR(250),
              publication VARCHAR(250),
              FOREIGN KEY (reviewer) REFERENCES reviewers(name) ON DELETE SET NULL,
              FOREIGN KEY (publication) REFERENCES publications(name) ON DELETE SET NULL
          );
        "
      become: true

    - name: Insert dotenv config line at the top of seeds.js
      lineinfile:
        path: /home/ubuntu/devops-rampup/movie-analyst-api/seeds.js
        line: "require('dotenv').config();"
        insertbefore: BOF

    - name: Insert dotenv config line at the top of server.js
      lineinfile:
        path: /home/ubuntu/devops-rampup/movie-analyst-api/server.js
        line: "require('dotenv').config();"
        insertbefore: BOF
      
    - name: Remove SET attribute from start script in package.json
      replace:
        path: /home/ubuntu/devops-rampup/movie-analyst-api/package.json
        regexp: '("start":\s*")SET\s+'
        replace: '\1'

    - name: Run seeds.js to seed the database
      command: node seeds.js
      args:
        chdir: /home/ubuntu/devops-rampup/movie-analyst-api
      become: true

    - name: Run server.js in detached mode
      shell: nohup npm start > output.log 2>&1 &
      args:
        chdir: /home/ubuntu/devops-rampup/movie-analyst-api
      become: true

EOF

# Confirm execution
echo "User data executed successfully"

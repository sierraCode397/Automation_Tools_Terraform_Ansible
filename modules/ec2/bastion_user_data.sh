#!/bin/bash
exec > /var/log/user-data.log 2>&1 
set -eux  # Debug mode: stop on error and print each command

cat <<EOF > /home/ubuntu/COMMANDS.txt

ansible all -i dynamic_inventory.py -m ping 



---- Set the "rds_endpoint" in the env vars of Backend and in the command of "mysql"

----Change the BACKEND_URL=load_balancer_dns with the DNS of the ALB



ansible-playbook -i inventory.ini frontend.yml

ansible-playbook -i inventory.ini backend.yml



----You should set "require('dotenv').config()" in server.js (Fron, Back) and seeds.js

----Detelete the SET comand of the "Package.json" of the Backend

----And then first run "seeds.js" after the "server.js Backend" and the last one "server.js Frontend"
EOF

cat <<EOF > /home/ubuntu/dynamic_inventory.py
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
EOF

cat <<EOF > /home/ubuntu/frontend.yml
---
- name: Setup Frontend Application
  hosts: frontend
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
          BACKEND_URL=10.0.2.200:3000
        dest: /home/ubuntu/devops-rampup/movie-analyst-ui/.env
        owner: ubuntu
        group: ubuntu
        mode: '0644'
EOF

cat <<EOF > /home/ubuntu/backend.yml
---
- name: Setup Backend Application
  hosts: backend
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
          DB_HOST=complete-mysql.ckpg8c2ewfpc.us-east-1.rds.amazonaws.com
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
        mysql -h complete-mysql.ckpg8c2ewfpc.us-east-1.rds.amazonaws.com -u admin -pAdminAdmin123 --connect-timeout=30 -e "
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
EOF

# Make the install_ansible.sh script executable
sudo chmod +x /home/ubuntu/dynamic_inventory.py

echo "install_ansible.sh script created..."
# Run the install_ansible.sh script
# sudo /home/ubuntu/install_ansible.sh
# echo "install_ansible.sh executed..." | sudo tee -a /home/ubuntu/userdata_success.log

# Confirm execution
echo "User data executed successfully"

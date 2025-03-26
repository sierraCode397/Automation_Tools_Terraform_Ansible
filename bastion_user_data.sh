#!/bin/bash
exec > /var/log/user-data.log 2>&1  # Log all output
set -eux  # Debug mode: stop on error and print each command

cat <<EOF > /home/ubuntu/COMMANDS.txt

Firts run install_ansible.sh

Send your SSH "scp -i ~/.ssh/user1.pem ~/.ssh/user1.pem ubuntu@ec2-CHANGETHIS.compute-1.amazonaws.com:/home/ubuntu/"

ansible all -m ping -i inventory.ini



---- Set the "rds_endpoint" in the env vars of Backend and in the command of "mysql"

----Change the BACKEND_URL=load_balancer_dns with the DNS of the ALB



ansible-playbook -i inventory.ini frontend.yml

ansible-playbook -i inventory.ini backend.yml



----You should set "require('dotenv').config()" in server.js (Fron, Back) and seeds.js

----Detelete the SET comand of the "Package.json" of the Backend

----And then first run "seeds.js" after the "server.js Backend" and the last one "server.js Frontend"
EOF

cat <<EOF > /home/ubuntu/inventory.ini
[frontend]
\$FRONTEND_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/user1.pem ansible_python_interpreter=/usr/bin/python3.12

[backend]
\$BACKEND_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/user1.pem ansible_python_interpreter=/usr/bin/python3.12
EOF

# Create a shell script to install Ansible
cat <<EOF > /home/ubuntu/install_ansible.sh
#!/bin/bash
# Update package list
sudo apt update -y
echo "Package list updated..." | sudo tee -a /home/ubuntu/userdata_success.log

# Install required dependencies (pipx, python3, etc.)
sudo apt install -y python3 python3-pip pipx
echo "Required dependencies installed..." | sudo tee -a /home/ubuntu/userdata_success.log

sudo apt install pipx -y
echo "Starting Ansible installation..." | sudo tee -a /home/ubuntu/install_ansible.log

pipx ensurepath
echo "pipx ensurepath..." | sudo tee -a /home/ubuntu/install_ansible.log

# Ensure that the shell knows about the new PATH
# exec $SHELL
echo "Shell reloaded..." | sudo tee -a /home/ubuntu/userdata_success.log

# Install Ansible using pipx
pipx install --include-deps ansible || echo "Ansible install failed" | sudo tee -a /home/ubuntu/install_ansible.log

# Install Ansible-core
pipx install ansible-core || echo "Ansible-core install failed" | sudo tee -a /home/ubuntu/install_ansible.log

sudo apt install ansible-core -y || echo "apt install ansible-core failed" | sudo tee -a /home/ubuntu/install_ansible.log
echo "ansible-core installed via apt..." | sudo tee -a /home/ubuntu/userdata_success.log

# Upgrade Ansible if needed
pipx upgrade --include-injected ansible || echo "Ansible upgrade failed" | sudo tee -a /home/ubuntu/install_ansible.log

# Check Ansible version
ANSIBLE_VERSION=\$(ansible --version 2>/dev/null | head -n 1 || echo "Ansible not installed")
echo "Ansible Version: \$ANSIBLE_VERSION" | sudo tee -a /home/ubuntu/install_ansible.log

echo "Ansible installation completed." | sudo tee -a /home/ubuntu/install_ansible.log
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
sudo chmod +x /home/ubuntu/install_ansible.sh

echo "install_ansible.sh script created..." | sudo tee -a /home/ubuntu/userdata_success.log

# Run the install_ansible.sh script
# sudo /home/ubuntu/install_ansible.sh
# echo "install_ansible.sh executed..." | sudo tee -a /home/ubuntu/userdata_success.log

# Confirm execution
echo "User data executed successfully" | sudo tee -a /home/ubuntu/userdata_success.log

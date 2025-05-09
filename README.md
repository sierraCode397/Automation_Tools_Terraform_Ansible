# Managing Terraform and ansible to Build and configure a Linux Infrastructure - Automation Tools

* 🚀 Deployed core network and compute resources using Terraform: VPC with public/private subnets, ELB, EC2 instances, RDS (MySQL), security groups, and NAT gateways.
* 🤖 Automated configuration with Ansible: Playbooks installed web servers, database nodes, system packages, and enforced security hardening across all EC2 hosts.
* 🐍 Wrote a Python script to generate a dynamic Ansible inventory, so new resources are discovered and configured automatically.

## Quick Overview

By shifting to a public cloud (AWS), you’ll find yourself:

* Spending less time on manual server chores and more on building cool features.
* Scaling up (or down) whenever you need without major headaches.
* Keeping costs in check by picking the right-sized services.
* Collaborating easily: Infrastructure as Code means everyone’s on the same page.

## Here’s the Gist

When you go cloud-native (AWS, Azure, or GCP), you’ll enjoy:

* **Effortless Scaling**: Spin up or down on demand, so you match capacity with real-world traffic.
* **Predictable Costs**: Right-size resources and keep an eye on spending via built-in tools.
* **Team Sync**: Store your infra definitions in code—no more “it works on my machine” surprises.
* **Reliability by Design**: Spread things out across subnets and availability zones for less downtime.

## Why It’s a Win

* **Agile Development**: Ship faster when infra changes are just a `git push`. Testing and production lanes coexist smoothly.
* **Operational Confidence**: Prebuilt monitoring and alerts mean you spot potential issues before they escalate.
* **Cost Awareness**: Use cloud-native budgeting tools; waste less and invest in features.
* **Future-Proofing**: Modular Terraform code lays the groundwork for next projects—and even multi-team collaboration.

## The Architecture in a Nutshell

Picture this setup:

1. **Load Balancer**: Routes traffic across healthy web servers.
2. **Compute Pool**: EC2 instances for front-end and API layers.
3. **Database Service**: Managed MySQL for easy backups and failover.
4. **Networking**: Public subnets for external endpoints, private for internal services, and a bastion host for secure access.
5. **Observability**: Dashboards and alarms tracking CPU, mem, network, DB latency, and more.

Swap in aws cloud services as needed—this is more of a pattern than a prescription.

## Let’s Get Hands-On

### 1. Prep Your Toolkit

* **Install**: Terraform CLI, your cloud’s CLI (aws/az/gcloud), and Ansible.
* **Login**: Make sure your IAM user has the rights to spin up stuff.
* **Clone**: `git clone https://github.com/aljoveza/devops-rampup.git`

### 2. Terraform Basics

1. **Remote State**: Set up an S3/Azure/GCS bucket so your state files aren’t on your laptop.
2. **Workspaces**: Keep QA and Prod separate.

3. **Modules**: Build bits for networking, compute, database, etc., in `/modules`.
4. **Spin It Up**:

```bash
# Initialize with remote state (S3/GCS/Storage Account)
terraform init -backend-config="..."

# Create separate contexts
tf workspace new qa
tf workspace new prod

# Plan & Apply in QA
cd environments/qa
tf plan && tf apply

# Switch to prod and repeat
terraform workspace select prod
tf plan && tf apply
```

   Then switch to `prod` and repeat.

### 3. Ansible Setup

1. **Inventory**: Use the cloud inventory plugin or a generated hosts file.
2. **Playbooks**: Review `playbooks/*.yml` for server prep, security hardening, and app deployment.
3. **Run It**:

   ```bash
   ansible-playbook -i inventory/hosts all.yml
   ```

### 4. Keep Tabs on Metrics

Most clouds have great monitoring built in:

* **AWS**: CloudWatch dashboards
* **Azure**: Azure Monitor
* **GCP**: Stackdriver Monitoring

Set up alerts for high CPU, low memory, or anything else that keeps you up at night.

## 5. Justification of Decisions

| Decision                      | Reasoning                                                  |
| ----------------------------- | ---------------------------------------------------------- |
| Terraform with Workspaces     | Isolate QA and Prod environments, maintain separate states |
| Remote State in Cloud Storage | Secure, shared state for remote team collaboration         |
| Modular Code Structure        | Promote reusability, simplify maintenance and onboarding   |
| Ansible for Configuration     | Streamline instance configuration, repeatable deployments  |
| In‑house Monitoring           | Cost‑effective, leverages existing cloud provider services |

## Architecture

Here is how the deployment must to looks like 

![AWS Academy Cloud Architecting](https://imgur.com/2zRYj8d.png)

## Why This Roadmap Rocks

* **Isolation**: QA and Prod don’t collide.
* **Reusability**: Modules mean less copy-paste.
* **Automation**: You’re not babysitting servers.
* **Visibility**: Real-time charts to catch issues early.

## What’s Next?

1. **Cost Review**: Compare initial spend against forecasts.
2. **CI/CD Integration**: Pipeline your Terraform and Ansible runs for hands-off deploys.
3. **Load Testing**: Simulate traffic to validate auto scaling and failover.
4. **Go-Live Prep**: Finalize rollback plans, update DNS, and celebrate a smooth launch.

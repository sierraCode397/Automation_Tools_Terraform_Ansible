# Managing Terraform and ansible to Build and configure a Linux Infrastructure - Automation Tools

Below is a laid-back roadmap to get you started with Terraform and Ansible.

---

## Quick Overview

By shifting to a public cloud (AWS, Azure, or GCP), you’ll find yourself:

* Spending less time on manual server chores and more on building cool features.
* Scaling up (or down) whenever you need without major headaches.
* Keeping costs in check by picking the right-sized services.
* Collaborating easily: Infrastructure as Code means everyone’s on the same page.

---

## What You’ll Gain

* **For Your Team**: Automation’s your new best friend—set it up once, then sit back (almost). Dev, QA, and Prod environments can live side by side without stepping on each other’s toes.
* **For Your Users**: Faster updates, better uptime, and dashboards that help you spot issues before they become drama.

---

## How It Fits Together

Imagine this:

* A couple of web servers behind a load balancer handling all your traffic.
* A managed database (MySQL) taking care of the data stuff.
* Public and private subnets, plus a bastion host you hop through for secure access.
* Cloud-native monitoring to keep an eye on CPU, memory, and network charts.

*Feel free to swap in your favorite services: AWS RDS vs. Azure Database vs. Cloud SQL—pick what you like.*

---

## Let’s Get Hands-On

### 1. Prep Your Toolkit

* **Install**: Terraform CLI, your cloud’s CLI (aws/az/gcloud), and Ansible.
* **Login**: Make sure your IAM user has the rights to spin up stuff.
* **Clone**: `git clone https://github.com/aljoveza/devops-rampup.git`

### 2. Terraform Basics

1. **Remote State**: Set up an S3/Azure/GCS bucket so your state files aren’t on your laptop.
2. **Workspaces**: Keep QA and Prod separate.

   ```bash
   terraform init -backend-config="..."
   terraform workspace new qa
   terraform workspace new prod
   ```
3. **Modules**: Build bits for networking, compute, database, etc., in `/modules`.
4. **Spin It Up**:

   ```bash
   cd environments/qa
   terraform plan && terraform apply
   ```

   Then switch to `prod` and repeat.

### 3. Ansible Magic

* **Inventory**: Use the Python script to get them dynamically.
* **Playbook**: In `playbooks/bastion-setup.yml`, you’ll configure your bastion and prep your servers.
* **Run**:

  ```bash
  ansible-playbook -i inventory/hosts bastion-setup.yml
  ```

### 4. Keep Tabs on Metrics

Most clouds have great monitoring built in:

* **AWS**: CloudWatch dashboards
* **Azure**: Azure Monitor
* **GCP**: Stackdriver Monitoring

Set up alerts for high CPU, low memory, or anything else that keeps you up at night.

---

## 5. Justification of Decisions

| Decision                      | Reasoning                                                  |
| ----------------------------- | ---------------------------------------------------------- |
| Terraform with Workspaces     | Isolate QA and Prod environments, maintain separate states |
| Remote State in Cloud Storage | Secure, shared state for remote team collaboration         |
| Modular Code Structure        | Promote reusability, simplify maintenance and onboarding   |
| Ansible for Configuration     | Streamline instance configuration, repeatable deployments  |
| In‑house Monitoring           | Cost‑effective, leverages existing cloud provider services |

---

![AWS Academy Cloud Architecting](https://imgur.com/2zRYj8d.png)

## Why This Roadmap Rocks

* **Isolation**: QA and Prod don’t collide.
* **Reusability**: Modules mean less copy-paste.
* **Automation**: You’re not babysitting servers.
* **Visibility**: Real-time charts to catch issues early.

---

## What’s Next?

1. Chat with your team about costs and timelines.
2. Hook this into your CI/CD pipeline.
3. Give QA a whirl—test it out before going live.
4. Plan your launch day (and a rollback, just in case).







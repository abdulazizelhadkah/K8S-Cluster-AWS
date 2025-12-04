# K8S-Cluster-AWS# Automated Kubernetes Cluster Deployment on AWS using Terraform and Ansible

---

## Project Overview

This project provides a comprehensive, automated solution for provisioning a highly available **Kubernetes cluster** on **Amazon Web Services (AWS)** using **Terraform** for infrastructure setup and **Ansible** for configuration management and Kubernetes deployment. The cluster is designed to be fault-tolerant and spans multiple **Availability Zones** within the `us-east-1` region.

### Infrastructure Architecture

The infrastructure is defined as code and follows the architecture depicted below:



![Infrastructure Diagram](Infrastructure%20Diagram.png)

* **VPC and Networking:** A Virtual Private Cloud (VPC) is established with both public and private subnets across three Availability Zones (`us-east-1a`, `us-east-1b`, and `us-east-1c`).
* **Bastion Host:** A dedicated **Bastion host** is deployed in the public subnet to allow secure SSH access to the private Kubernetes nodes.
* **Kubernetes Control Plane (Master Nodes):** Three **Master Nodes** are provisioned, one in each private subnet for high availability.
* **Kubernetes Worker Nodes:** Three **Worker Nodes** are provisioned, one in each private subnet.
* **Load Balancing:** A **Network Load Balancer (NLB)** is used to distribute traffic across the Kubernetes nodes, providing a stable entry point for the cluster.

---

## Repository Structure

The project directory is organized to separate infrastructure provisioning (`Terraform`) from configuration management (`ansible`).

* **`.vscode/`:** Visual Studio Code configuration files (optional).
* **`ansible/`:** Contains all Ansible configuration files.
    * `ansible.cfg`: Ansible configuration file.
    * `k8s-key.pem`: SSH private key used by Ansible to connect to AWS instances.
    * `playbook.yml`: The main Ansible playbook for installing and configuring Kubernetes.
* **`Terraform/`:** Contains all Terraform configuration files (`.tf`).
    * `asg.tf`, `ec2.tf`, `lb.tf`, `vpc.tf`, etc.: Modules defining AWS resources.
    * `inventory.tpl`: Jinja template for generating the dynamic Ansible inventory file.
    * `variables.tf`: Input variables for the Terraform configuration.
* **`deploy.sh`:** A shell script to execute the complete deployment process (Terraform and Ansible).
* **`destroy.sh`:** A shell script to tear down the entire infrastructure.
* **`k8s-key.pem`:** The required SSH key pair file.

---

## Prerequisites

To run this project, you must have the following installed and configured:

1.  **AWS Account and Credentials:** Configured with appropriate IAM permissions.
2.  **Terraform:** Installed and on your system PATH.
3.  **Ansible:** Installed and on your system PATH.
4.  **SSH Key Pair:** The private key (`k8s-key.pem`) must be present in the root directory and the `ansible/` directory.

---

## Deployment Instructions

The entire deployment process is managed by the `deploy.sh` script.

1.  **Set Permissions for the SSH Key:**
    Ensure your private key file has the correct permissions:
    ```bash
    chmod 400 k8s-key.pem
    ```

2.  **Execute Deployment Script:**
    Run the deployment script from the root directory:
    ```bash
    ./deploy.sh
    ```

### What `deploy.sh` does:

* It navigates to the `Terraform/` directory, runs `terraform init`, and executes `terraform apply -auto-approve` to provision all AWS resources (VPC, subnets, EC2 nodes, NLB, etc.).
* It uses the Terraform outputs to generate a dynamic Ansible inventory file.
* It executes Ansible using the generated inventory and the `ansible/playbook.yml` to:
    * Install necessary dependencies (e.g., Docker, kubeadm, kubelet).
    * Initialize the Kubernetes cluster on the Master Nodes.
    * Join the Worker Nodes to the cluster.

---

## Cleanup

To completely remove all provisioned AWS resources and local state files, run the `destroy.sh` script:

```bash
./destroy.sh

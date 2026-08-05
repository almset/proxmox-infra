# Proxmox Infrastructure as Code Platform

Production-ready Infrastructure as Code platform for building and managing virtual infrastructure on Proxmox.

The project provides a complete automation pipeline that covers the entire infrastructure lifecycle:

* Building reusable virtual machine templates
* Provisioning virtual machines
* Configuring operating systems and infrastructure services
* Bootstrapping Kubernetes clusters
* Deploying applications using GitOps

The repository combines several Infrastructure as Code technologies into a single workflow.

## Architecture

```text
                Packer
                   │
        Build VM Templates
                   │
                   ▼
     Ubuntu / Windows Templates
                   │
                   ▼
      Terragrunt / Terraform
                   │
      Provision Virtual Machines
                   │
                   ▼
              Ansible
                   │
 Configure Operating Systems & Services
                   │
                   ▼
       Kubernetes Cluster Ready
                   │
                   ▼
      Ansible GitOps Bootstrap
                   │
                   ▼
                Argo CD
                   │
                   ▼
      Git Repository (GitOps)
                   │
                   ▼
   Platform Components & Applications
```

## Components

### Packer

Creates reusable VM templates for Proxmox.

Typical template configuration includes:

* Ubuntu Server
* Windows Server
* QEMU Guest Agent
* Cloud-Init
* Security hardening
* Monitoring agents (optional)
* Common system packages

The generated templates become the base images used by Terraform.

---

### Terragrunt / Terraform

Creates the virtual infrastructure from Packer templates.

Examples include:

* Bastion Host
* Gateway Router
* DNS Server
* Kubernetes Control Plane
* Kubernetes Worker Nodes
* Monitoring Servers
* Storage Nodes

Infrastructure is fully declarative and can be recreated at any time.

---

### Ansible

Configures all provisioned virtual machines.

Examples:

* Base OS configuration
* Package management
* Firewall
* SSH hardening
* Time synchronization
* DNS (Bind9)
* Gateway (iptables / NAT)
* Container Runtime
* Kubernetes (RKE2 or kubeadm)
* Monitoring
* Security hardening

Dynamic inventory is generated automatically from Terraform outputs.

---

### Ansible Kubernetes Platform

Bootstraps a Kubernetes platform.

Responsibilities include:

* Installing Argo CD
* Connecting Argo CD to a Git repository
* Preparing the cluster for GitOps

Application deployment is intentionally left to GitOps.

---

### GitOps Repository

Once Argo CD is installed, all Kubernetes resources are managed from a Git repository.

Typical resources include:

* Namespaces
* Applications
* Helm Charts
* Platform Components
* Ingress
* Certificates
* Monitoring Stack
* Storage
* Custom Workloads

This keeps the infrastructure immutable and version-controlled.

## Typical Workflow

```text
1. Build VM templates
        │
        ▼
2. Provision virtual machines
        │
        ▼
3. Configure infrastructure
        │
        ▼
4. Bootstrap Kubernetes
        │
        ▼
5. Install Argo CD
        │
        ▼
6. Sync GitOps repository
        │
        ▼
7. Kubernetes platform becomes fully operational
```

## Repository Structure

```text
packer/                  Build VM templates

terragrunt/              Provision Proxmox virtual machines

ansible/                 Configure infrastructure

ansible-k8s-platform/    Bootstrap Kubernetes and Argo CD

gitops/                  Example GitOps repository
```

## Goals

* Fully automated infrastructure provisioning
* Declarative Infrastructure as Code
* Reproducible environments
* Production-ready Kubernetes bootstrap
* GitOps-driven application deployment
* Modular and reusable architecture

## Quick Start

The deployment process consists of four independent stages.

### 1. Build VM Templates

Create reusable Ubuntu or Windows templates with Packer.

```bash
cd packer

packer init .
packer validate .
packer build ubuntu-server.pkr.hcl
```

After completion, a Proxmox VM template will be available.

---

### 2. Provision Virtual Machines

Deploy the infrastructure using Terragrunt.

```bash
cd terragrunt/live/production

terragrunt run-all apply
```

This stage creates all required virtual machines, for example:

* Bastion Host
* Gateway
* DNS Server
* Kubernetes Control Plane
* Kubernetes Worker Nodes

Terraform outputs are automatically used later by Ansible Dynamic Inventory.

---

### 3. Configure Infrastructure

Configure all virtual machines.

```bash
cd ansible

./scripts/start.sh bootstrap
```

or execute the complete playbook.

```bash
ansible-playbook playbooks/site.yml
```

Typical tasks include:

* Operating system configuration
* Package installation
* SSH hardening
* Firewall configuration
* DNS server
* Gateway
* Kubernetes installation (RKE2 or kubeadm)

---

### 4. Bootstrap Kubernetes Platform

Install Argo CD and connect it to your GitOps repository.

```bash
cd ansible-k8s-platform

ansible-playbook playbooks/platform.yml
```

Configure your Git repository URL in the inventory or group variables before deployment.

After Argo CD is installed, the cluster automatically synchronizes with your GitOps repository.

---

## Verify Deployment

Check Terraform resources.

```bash
terragrunt output
```

Check Ansible connectivity.

```bash
ansible all -m ping
```

Verify Kubernetes.

```bash
kubectl get nodes
```

Verify Argo CD.

```bash
kubectl get pods -n argocd
```

If the GitOps repository is configured correctly, Argo CD will automatically deploy all platform components and applications.

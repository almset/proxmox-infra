# Kubeadm Ansible Role

Production-oriented Ansible role for installing Kubernetes via kubeadm.

## 🏗 Architecture & Pipeline

```mermaid
graph TD
    A[Facts & Validation] --> B[Preflight Checks]
    B --> C[Cleanup (if requested)]
    C --> D[Install Packages]
    D --> E[Configure Kubelet]
    E --> F{Mode?}
    F -->|kubeadm_upgrade=true| U[Upgrade Pipeline]
    F -->|kubeadm_bootstrap=true| G[Pre-pull Images & kubeadm init]
    F -->|default| H[kubeadm join]
    G --> I[Apply CNI & Wait for Ready]
    H --> I
    I --> J[Export Kubeconfig]
    J --> K[Post-install Validation]
    K --> L((Cluster Ready))
    U --> M((Upgrade Complete))

    style G fill:#d4edda,stroke:#28a745
    style H fill:#cce5ff,stroke:#007bff
    style U fill:#fff3cd,stroke:#ffc107
    style L fill:#d4edda,stroke:#28a745
    style M fill:#fff3cd,stroke:#ffc107

> **Note:** Bootstrap, Join, and Upgrade are **mutually exclusive modes**. The role automatically selects the correct pipeline based on `kubeadm_bootstrap` and `kubeadm_upgrade` flags.

## 🚀 Zero-Secret Join Architecture (v1.0.0)

The role uses a **race-condition-free, on-demand secret generation** model:

### How It Works

1. **CA Hash (Optional, Per-Join):** If `kubeadm_ca_cert_hash` is explicitly provided in inventory, it is used directly. Otherwise, each joining node independently computes the CA hash by delegating `openssl` to the bootstrap host.
2. **Join Tokens (Per-Node):** Each joining node independently creates its own token by delegating `kubeadm token create` to the bootstrap host. This completely eliminates race conditions, regardless of `strategy: free`, `serial: 1`, or `forks: 20`.
3. **Certificate Keys (Per-Control-Plane-Join):** Each control-plane join refreshes the cluster's `upload-certs` secret and receives a fresh certificate key. Keys are cheap and short-lived (2h TTL).
4. **Native Garbage Collection:** All tokens and keys use Kubernetes' native TTL-based GC. No manual cleanup required.

### Why This Architecture?

- **No Race Conditions:** Each node gets its own secrets. No `hostvars` synchronization, no `delegate_facts`, no `run_once` complexity.
- **Works with Any Strategy:** `linear`, `free`, `serial: 1` — all work correctly.
- **Supports Existing Clusters:** You can join nodes to an existing cluster at any time. The role will generate fresh secrets on-demand.
- **Simplicity:** Less code, fewer edge cases, easier to debug.

### ⚠️ Important Concepts

- **Fully Local Secrets:** All secrets (CA hash, tokens, certificate keys) are computed locally for each join operation or provided explicitly. No persistent state is shared via `hostvars`.
- **Bootstrap Host vs. API Endpoint:**
    - `kubeadm_bootstrap_host` — the source of secrets (where `token create` and `upload-certs` execute).
    - `kubeadm_api_endpoint` — the network entry point (HAProxy/VIP).
    - These can be different in HA clusters.
- **HA Clusters:** If `k8s_control_plane` has >1 node, you **must** explicitly define `kubeadm_bootstrap_host` to avoid ambiguity.
- **Kubernetes Version Compatibility:** This role is tested with Kubernetes 1.28–1.31. The parsing of `kubeadm` command output relies on the current stdout format.

## ⚠️ CRITICAL WARNING FOR UPGRADES

When upgrading control-plane nodes, you **MUST** run the playbook with `serial: 1`. The role includes an internal assertion to enforce this.

**Upgrade is a mutually exclusive mode:** when `kubeadm_upgrade: true`, the role skips bootstrap and join entirely. Worker drain/uncordon operations are automatically delegated to the bootstrap host (workers do not have `admin.conf`).

## Prerequisites

- **containerd** must be installed and running (min 1.6.0).
- **Swap must be disabled**.
- **NTP must be synchronized** (if `timedatectl` is available).
- **CNI Manifest**: Place your desired CNI manifest in `roles/kubeadm/files/<plugin>/<version>.yaml`.
- **Kube-proxy**: If you use Cilium with kube-proxy replacement, set `kubeadm_install_kube_proxy: false`.
- **Air-gap**: Set `kubeadm_image_repository: "your-internal-registry.com"`.

## Features

- ✅ Idempotent installation with strict version pinning
- ✅ Mutually exclusive modes: bootstrap / join / upgrade
- ✅ Safe, block/always guaranteed upgrade with version skew validation
- ✅ Worker drain/uncordon delegated to control-plane (no admin.conf needed on workers)
- ✅ Pre-pull images before init with retry logic
- ✅ CNI applied only if not already installed
- ✅ Race-condition-free join architecture
- ✅ Kubeconfig export via official `kubectl config set-cluster`

## Example Inventories

### HA Cluster (Recommended)

ini

1

2

3

4

5

6

7

8

9

10

11

## Example Playbook

### Install

yaml

1

2

3

4

5

6

7

8

9

10

11

12

13

### Upgrade

yaml

1

2

3

4

5

6

7

8

9

10

11

12

13

14

15

16

17

18

## Cleanup Safety

- `kubeadm_cleanup_full: true` — Performs `kubeadm reset -f` and cleans directories.
- `kubeadm_cleanup_etcd: true` — **DANGEROUS**. Requires `kubeadm_confirm_cleanup: true`.

## Testing (Molecule)

Molecule verifies only syntax and basic structure (binary existence, package holds, template rendering). Functional testing requires Libvirt/Vagrant/Incus as Docker cannot run full kubeadm init.

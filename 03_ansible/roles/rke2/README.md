# RKE2 Ansible Role

Production-oriented Ansible role for installing and configuring RKE2 (Rancher Kubernetes Engine 2).

## ⚠️ CRITICAL WARNING FOR HA CLUSTERS
When upgrading or applying changes to an HA control plane, you **MUST** run the playbook with `serial: 1`.

## Features

- ✅ Idempotent installation with version pinning
- ✅ Safe upgrade path validation (blocks minor version skipping AND downgrades)
- ✅ Air-gapped environment support (`INSTALL_RKE2_ARTIFACT_PATH`, `INSTALL_RKE2_METHOD`)
- ✅ Full registry configuration via `registries.yaml` (mirrors, auth, TLS)
- ✅ Kubernetes component argument customization (kubelet, apiserver, scheduler, controller-manager, etcd)
- ✅ Automatic manifest deployment (supports both Jinja2 templates and static YAML)
- ✅ PATH export for administrative tools
- ✅ ETCD snapshot scheduling and retention
- ✅ Cloud provider integration
- ✅ SELinux support (ready for RHEL-family)
- ✅ Strict security (config file permissions, mandatory tokens)

## Dependencies

- **OS**: Ubuntu 22.04 LTS or 24.04 LTS
- **Collections**: `ansible.utils` (for CIDR validation)
- **Note**: RKE2 bundles its own containerd. Do not install an external containerd.

## Token Management

The `rke2_token` variable is **REQUIRED** for all nodes. Use Ansible Vault or `group_vars` to provide it securely.

## Air-Gapped Support

```yaml
rke2_install_artifact_path: "/opt/rke2-artifacts"
rke2_install_method: "tarball"
rke2_system_default_registry: "registry.internal.local"
rke2_registries:
  mirrors:
    docker.io:
      endpoint:
        - "https://registry.internal.local"
```

## Registries Configuration

Two ways to configure registries:

**Simple (legacy)**
```yaml
registries: {}
Full (recommended for production)

yaml
registries:
  docker.io:
    endpoint: "https://registry-1.docker.io"
    config:
      auth:
        username: "user"
        password: "pass"
  quay.io:
    endpoint: "https://quay.io"
```

Custom Kubernetes Component Arguments
```yaml
kubelet_extra_args:
  - "--eviction-hard=memory.available<500Mi"
  - "--max-pods=110"
```
Custom Manifests
Place manifests in two locations:
templates/manifests/ — Jinja2 templates (rendered before deployment)

files/manifests/ — Static YAML files (copied as-is)

```yaml
custom_manifests:
  - manifests/ingress-nginx.yaml
  - manifests/metrics-server.yaml
```

ETCD Snapshot Configuration
```yaml
etcd_snapshot:
  schedule: "0 */6 * * *"
  retention: 5
  bucket: "s3://my-bucket/etcd-snapshots"
```
PATH Export
By default, RKE2 binaries (kubectl, crictl, ctr) are exported to /etc/profile.d/rke2.sh for all users. Disable with:

```yaml
rke2_export_path: false
Upgrade Validation
The role validates upgrade paths:
```
Path	Status
1.29 → 1.30	✅ Sequential upgrade (allowed)
1.29 → 1.31	❌ Skipping minor version (BLOCKED)
1.31 → 1.30	❌ Downgrade (BLOCKED)

Testing
Molecule scenarios validate file permissions, template rendering, and systemd states. Docker cannot run full Kubernetes clusters reliably. For E2E validation, use Vagrant, Libvirt, or bare-metal CI runners.

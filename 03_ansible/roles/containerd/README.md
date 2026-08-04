# Containerd Role Documentation

## Supported Scope

### Role Responsibilities
- ✔ Install containerd.io 2.2+ from Docker repository
- ✔ Configure containerd for Kubernetes via drop-in overrides (conf.d)
- ✔ Auto-detect and purge legacy Docker/1.7.x configurations
- ✔ Setup registry mirrors (Containerd 2.x format: certs.d / hosts.toml)
- ✔ Optional: Load kernel modules and configure sysctl parameters

### Out of Scope
- ✘ Install kubelet, kubeadm, kubectl
- ✘ Install CNI plugins
- ✘ Manage alternative runtimes (cri-o, kata)

## Compatibility & Version Support

| Component | Supported Versions |
|-----------|-------------------|
| OS | Ubuntu 24.04 LTS (Noble), 22.04 LTS (Jammy)* |
| Ansible | 2.16+ |
| Containerd | 2.2.x or higher (strict requirement, enforced via fail-fast check) |
| Kubernetes | 1.30+ |

\* Ubuntu 22.04 may default to 1.7.x. If using 22.04, explicitly pin `containerd_version: "2.2.0-1"` or similar from Docker repo.

## Configuration Strategy (Drop-in Overrides)

This role uses the "vendor config + drop-in overrides" pattern, which is the modern enterprise standard for managing containerd:

1. **Version Gate**: Before any configuration, the role verifies that the containerd binary exists and is version 2.2+. If not, it fails fast with a clear error.

2. **Legacy Detection**: Uses native `slurp` + `regex_search` to detect legacy configs (absence of `version = 3` OR `disabled_plugins` containing "cri"). If found, the main config is deleted.

3. **Safe Generation**: Runs `containerd config default` to get the upstream-supported v3 format.

4. **Imports Guarantee**: After generation, the role verifies that `imports = ['/etc/containerd/conf.d/*.toml']` exists in the main config (inserted safely after the version line). If missing, it's added automatically.

5. **Drop-in Overrides**: Instead of fragile replace operations on the main `config.toml`, the role deploys `/etc/containerd/conf.d/99-kubernetes.toml`. This file explicitly sets sandbox and SystemdCgroup via the proper 2.2+ plugin paths.

6. **Running State Validation**: Post-installation, the role validates the active merged configuration using `containerd config dump` (not just the file on disk). It uses strict `regex_search` to verify that `SystemdCgroup = true` and the exact sandbox image are present in the running daemon.

7. **Plugin Health Check**: The CRI plugin status is verified by parsing `ctr plugins ls` output line-by-line using `select('search', ...)`, ensuring the plugin is not only present but explicitly in an `ok` state.

This approach ensures the role is resilient within the supported configuration model: it cleanly separates Kubernetes-specific overrides from the vendor default config, minimizing breakage from minor upstream changes.

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `containerd_cleanup` | `false` | If true, removes packages listed in `containerd_cleanup_packages`. |
| `containerd_cleanup_packages` | `[docker.io, docker, docker-ce, containerd]` | Packages to remove if cleanup is enabled (excludes target package). |
| `containerd_cleanup_autoremove` | `false` | If true, also removes orphaned dependencies. Disabled by default for safety. |
| `containerd_manage_repository` | `true` | Set to false if the Docker repository is managed by the base role. |
| `containerd_manage_gpg_key` | `true` | Set to false if the Docker GPG key is managed by another role. |
| `containerd_manage_kernel` | `true` | Set to false if kernel modules are managed centrally by the hardening role. |
| `containerd_manage_sysctl` | `true` | Set to false if sysctl parameters are managed centrally. |
| `containerd_version` | `""` | Leave empty for latest 2.2+. Or pin to full version (e.g., '2.2.0-1'). |
| `containerd_docker_gpg_checksum` | `""` | Optional SHA256 checksum for Docker GPG key. |
| `containerd_arch_map` | (see defaults) | Architecture mapping for `deb822_repository`. |
| `containerd_regenerate_config` | `false` | Force regeneration. (Auto-triggered if legacy config is detected). |
| `containerd_systemd_cgroup` | `true` | Enable SystemdCgroup (required for K8s). |
| `containerd_sandbox_image` | `registry.k8s.io/pause:3.10.1` | Updated default for modern Kubernetes. |

## Idempotency & Check Mode

This role is fully idempotent and supports `--check` mode:

- Main config is only regenerated when legacy is detected or explicitly requested
- Drop-in overrides are written via template (idempotent by design)
- `imports` directive is added only if missing
- Sysctl parameters are applied via a handler only when values change
- All diagnostic commands use `changed_when: false`
- Post-installation validation is safely skipped during `--check` mode to prevent false positives

## Example Playbook

```yaml
- hosts: kubernetes_nodes
  roles:
    - role: containerd
      vars:
        containerd_systemd_cgroup: true
        containerd_sandbox_image: registry.k8s.io/pause:3.10.1
        containerd_version: "2.2.0-1"
        containerd_cleanup: true

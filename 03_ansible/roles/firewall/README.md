# Ansible Role: firewall

Firewall management role for Ubuntu servers using UFW (Uncomplicated Firewall).

## Purpose

- Install and configure UFW
- Manage default policies (incoming/outgoing/forwarding)
- Allow SSH access
- Apply additional rules (ports, IPs)

**Does NOT manage:**
- SSH hardening → `hardening` role
- Intrusion prevention → `fail2ban` role
- Audit system → `auditd` role
- iptables/nftables directly (only through UFW)

## Requirements

- Ubuntu Server 22.04+
- Ansible 2.16+
- `become` privileges (root access)
- `base` role should be executed first

This role assumes that the `base` role has already configured package repositories, time synchronization, and common system settings.

This role also assumes that package metadata has already been updated (for example by the `base` role), so it does not run `apt update` before installing UFW.

## Collections

This role requires the `community.general` collection.

Install at the project level:

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

Or install directly:

```bash
ansible-galaxy collection install community.general
```

## Supported OS

- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 24.04 LTS (Noble)

## Role Variables

### Default policies

| Variable | Default | Description |
|----------|---------|-------------|
| `firewall_ufw_default_input` | `deny` | Default incoming policy |
| `firewall_ufw_default_output` | `allow` | Default outgoing policy |
| `firewall_ufw_default_forward` | `deny` | Default forwarding policy |
| `firewall_ufw_logging` | `on` | Logging level (`on`, `off`, `low`, `medium`, `high`, `full`) |

### SSH access

| Variable | Default | Description |
|----------|---------|-------------|
| `firewall_ufw_ssh_enabled` | `true` | Allow SSH |
| `firewall_ufw_ssh_port` | `22` | SSH port (1-65535) |

### Extra rules

| Variable | Default | Description |
|----------|---------|-------------|
| `firewall_rules` | `[]` | List of additional rules |

### Reset

| Variable | Default | Description |
|----------|---------|-------------|
| `firewall_ufw_reset` | `false` | Reset UFW to factory defaults |

## Dependencies

None.

## Example Playbook

### Basic firewall (SSH only)

```yaml
- hosts: all
  become: yes
  roles:
    - role: firewall
```

### Web server (SSH + HTTP + HTTPS)

```yaml
- hosts: webservers
  become: yes
  roles:
    - role: firewall
      vars:
        firewall_rules:
          - { rule: 'allow', port: '80', proto: 'tcp', comment: 'HTTP' }
          - { rule: 'allow', port: '443', proto: 'tcp', comment: 'HTTPS' }
```

### DNS server

```yaml
- hosts: dns_servers
  become: yes
  roles:
    - role: firewall
      vars:
        firewall_rules:
          - { rule: 'allow', port: '53', proto: 'tcp', comment: 'DNS TCP' }
          - { rule: 'allow', port: '53', proto: 'udp', comment: 'DNS UDP' }
          - { rule: 'allow', port: '953', proto: 'tcp', comment: 'RNDC' }
```

### Kubernetes API (with IP restriction)

```yaml
- hosts: k8s_masters
  become: yes
  roles:
    - role: firewall
      vars:
        firewall_rules:
          - { rule: 'allow', from_ip: '10.0.0.0/8', to_port: '6443', proto: 'tcp', comment: 'K8s API from internal' }
          - { rule: 'allow', port: '6443', proto: 'tcp', comment: 'K8s API public' }
          - { rule: 'allow', port: '2379:2380', proto: 'tcp', comment: 'etcd' }
          - { rule: 'allow', port: '10250', proto: 'tcp', comment: 'Kubelet' }
```

### Database (access only from subnet)

```yaml
- hosts: databases
  become: yes
  roles:
    - role: firewall
      vars:
        firewall_rules:
          - { rule: 'allow', from_ip: '10.0.0.0/8', to_port: '5432', proto: 'tcp', comment: 'PostgreSQL from internal' }
```

## Example Inventory

### `group_vars/webservers.yml`

```yaml
---
firewall_rules:
  - { rule: 'allow', port: '80', proto: 'tcp', comment: 'HTTP' }
  - { rule: 'allow', port: '443', proto: 'tcp', comment: 'HTTPS' }
  - { rule: 'allow', port: '8080', proto: 'tcp', comment: 'App' }
```

### `group_vars/databases.yml`

```yaml
---
firewall_ufw_ssh_port: 2222  # non-standard SSH port
firewall_rules:
  - { rule: 'allow', from_ip: '10.0.1.0/24', to_port: '3306', proto: 'tcp', comment: 'MySQL from app subnet' }
```

### `group_vars/k8s_nodes.yml`

```yaml
---
firewall_rules:
  - { rule: 'allow', port: '6443', proto: 'tcp', comment: 'K8s API' }
  - { rule: 'allow', port: '10250', proto: 'tcp', comment: 'Kubelet' }
  - { rule: 'allow', port: '30000:32767', proto: 'tcp', comment: 'NodePort range' }
```

## Tags

| Tag | Description |
|-----|-------------|
| `firewall` | All tasks |
| `preflight` | OS check |
| `validate` | Variable validation |
| `ufw` | UFW configuration |

Examples:

```bash
# UFW only
ansible-playbook site.yml --tags ufw

# Skip preflight
ansible-playbook site.yml --skip-tags preflight
```

## ⚠️ Warnings

1. **SSH access:** SSH (port 22) is allowed by default. If you use a non-standard port, configure `firewall_ufw_ssh_port`.
2. **Default policy:** `deny` by default. If you have services, add them to `firewall_rules`.
3. **Docker:** UFW and Docker can conflict. For Docker hosts, use `firewall_ufw_default_forward: deny` and manage rules explicitly.
4. **Reset:** To reset UFW to factory defaults before applying, set `firewall_ufw_reset: true`.

## ⚠️ Testing limitations

Molecule tests run inside Docker containers. UFW inside Docker has known limitations:

- UFW manipulates `iptables`/`nftables`, but Docker manages its own iptables rules for port forwarding.
- Some rules may not apply as expected due to kernel namespace isolation.
- The `privileged: true` and `NET_ADMIN` capability are required, but behavior still differs from bare metal.

**For production validation**, test the role on a real VM (Vagrant, libvirt, or cloud instance) before applying to production servers.

The Docker-based tests verify **role logic** (variables, tasks, idempotency), but not **firewall behavior** at the kernel level.

## Extra rules format

### Port-based rules

```yaml
firewall_rules:
  - { rule: 'allow', port: '80', proto: 'tcp', comment: 'HTTP' }
  - { rule: 'allow', port: '53', proto: 'udp', comment: 'DNS' }
  - { rule: 'allow', port: '30000:32767', proto: 'tcp', comment: 'NodePort' }
  - { rule: 'deny', port: '25', proto: 'tcp', comment: 'Block SMTP' }
```

### IP-based rules

```yaml
firewall_rules:
  - { rule: 'allow', from_ip: '10.0.0.0/8', to_port: '22', proto: 'tcp', comment: 'SSH from internal' }
  - { rule: 'allow', from_ip: '192.168.1.100', to_port: '3306', proto: 'tcp', comment: 'MySQL from specific IP' }
```

## Testing

```bash
# Run Molecule tests
cd roles/firewall
molecule test

# Converge only
molecule converge

# Verify only
molecule verify

# Destroy
molecule destroy
```

## Production readiness

The role is ready for use in production Ubuntu environments where UFW is accepted as the standard firewall and meets infrastructure requirements.

## License

MIT

## Author Information

Created for managing firewall on Ubuntu servers in infrastructure.

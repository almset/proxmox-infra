# Ansible Role: auditd

Install and configure `auditd` with custom audit rules on Linux systems.

> **Note:** This role does **not** attempt to provide CIS/STIG compliance.
> It installs a baseline configuration that can be extended for your
> specific security requirements.

## Requirements

| Requirement   | Detail                              |
| ------------- | ----------------------------------- |
| OS            | Linux (Debian/Ubuntu, RHEL/Rocky)   |
| Init system   | systemd                             |
| Ansible       | >= 2.15                             |
| Privileges    | `become: true`                      |

## Supported Platforms

| OS     | Version | Status |
| ------ | ------- | ------ |
| Ubuntu | 22.04   | ✅      |
| Ubuntu | 24.04   | ✅      |
| Debian | 12      | ✅      |
| Rocky  | 9       | ✅      |

## Role Variables

All variables are defined in [`defaults/main.yml`](defaults/main.yml) and
documented in [`meta/argument_specs.yml`](meta/argument_specs.yml).

| Variable              | Default   | Description                                      |
| --------------------- | --------- | ------------------------------------------------ |
| `auditd_enabled`      | `true`    | Enable / disable the role                        |
| `auditd_debug`        | `false`   | Extra output during validation                   |
| `auditd_immutable`    | `false`   | Lock rules after load (`-e 2`, needs reboot)     |
| `auditd_conf`         | *see defaults* | `/etc/audit/auditd.conf` key-value pairs     |
| `auditd_rules`        | *see defaults* | List of rule file definitions                |
| `auditd_packages_map` | *see defaults* | Packages per OS family                       |

## Role Workflow


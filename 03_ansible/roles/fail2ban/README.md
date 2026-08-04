# Ansible Role: fail2ban

Install and configure **fail2ban** on Ubuntu/Debian systems with safe, idempotent cleanup of managed jails.

## Role Design

This role follows a **minimal intervention** philosophy:

### Generated files

The following files are actively managed by this role and will be overwritten on subsequent runs:

- `/etc/fail2ban/jail.local` — global configuration
- `/etc/fail2ban/jail.d/05-recidive.local` — recidive jail (persistent offenders)
- `/etc/fail2ban/jail.d/10-sshd.local` — SSH jail
- `/etc/fail2ban/jail.d/10-*.local` — extra jails (managed via `fail2ban_extra_jails`)

### Files not managed

The following files are **intentionally untouched** by this role. You can safely modify them manually:

- `/etc/fail2ban/fail2ban.conf` — main daemon configuration
- `/etc/fail2ban/jail.conf` — package default jails
- `/etc/fail2ban/filter.d/*` and `/etc/fail2ban/action.d/*` — filters and actions
- Any file in `/etc/fail2ban/jail.d/` that does **not** start with `05-recidive.` or `10-`

This approach ensures:

- No conflicts with package updates
- Admin can safely add custom jails
- Role is idempotent and predictable
- Cleanup removes only managed files

## Compatibility

| Platform | Version | Status |
|---|---|---|
| Ubuntu | 22.04 (Jammy) | ✅ Tested |
| Ubuntu | 24.04 (Noble) | ✅ Tested |
| Debian | 11 (Bullseye) | ⚠️ Untested |
| Debian | 12 (Bookworm) | ⚠️ Untested |
| Fail2ban | 0.11+ | ✅ Supported |
| Ansible | 2.14+ | ✅ Required |

## Recommendations

For **Ubuntu 22.04+** systems, consider overriding defaults:

```yaml
fail2ban_default:
  backend: systemd              # faster, no polling issues
  banaction: nftables-multiport # modern, better performance
```

Default values (`backend: auto`, `banaction: iptables-multiport`) ensure maximum portability across different environments (Docker, LXC, containers without journald).

## Known limitations

- Email notifications are disabled by default
- `bantime.formula` requires fail2ban ≥ 0.10
- Cleanup is disabled by default (enable explicitly with `fail2ban_cleanup_enabled: true`)
- Uses `iptables-multiport` by default (switch to `nftables-multiport` for modern systems)
- Does not manage custom filter definitions
- Does not integrate with external log aggregation systems
- `logpath` is ignored when `backend: systemd` (journald is used instead)

## Features

- ✅ Install fail2ban from official repositories
- ✅ Configure global settings with `auto` backend (portable)
- ✅ Enable SSH jail with progressive ban time
- ✅ **Recidive jail** for persistent offenders (1 week ban)
- ✅ Add arbitrary extra jails via a simple list
- ✅ **Safe cleanup**: only files managed by the role are removed (disabled by default)
- ✅ **Configuration validation** before restart/reload
- ✅ **Reload handler** for jail-only changes (faster than restart)
- ✅ Fully idempotent and Molecule-tested
- ✅ FQCN module names, `true`/`false` booleans
- ✅ Dictionary-based configuration for consistency
- ✅ Uses `systemd` module for service management
- ✅ Modern `argument_specs.yml` for variable validation
- ✅ Read-only verification via `service_facts`
- ✅ `.ansible-lint` configuration included

## Requirements

- Ansible ≥ 2.14
- Ubuntu/Debian target hosts
- `systemd` as init system (for service management)

## Role Variables

See [`defaults/main.yml`](defaults/main.yml) and [`meta/argument_specs.yml`](meta/argument_specs.yml) for the full list.

### Service

| Variable | Default | Description |
|---|---|---|
| `fail2ban_service_name` | `fail2ban` | Service name |
| `fail2ban_service_state` | `started` | Desired service state |
| `fail2ban_service_enabled` | `true` | Enable at boot |
| `fail2ban_manage_service` | `true` | Manage service state (set `false` if managed externally) |

### Global configuration (dictionary)

```yaml
fail2ban_default:
  backend: auto                  # auto/systemd/polling
  banaction: iptables-multiport  # iptables-multiport/nftables-multiport
  bantime: 3600
  findtime: 600
  maxretry: 5
  bantime_increment: true
  bantime_factor: 1
  bantime_formula_enabled: true
  bantime_formula: "ban.Time * (1.0 + banFactor*log(1+banCount))"
  bantime_overalljails: true
  ignoreip:
    - 127.0.0.1/8
    - ::1
```

**Backend options:**

- `auto` (default) — automatic detection (recommended for portability)
- `systemd` — systemd journal (recommended for Ubuntu 22.04+ with journald)
- `polling` — file polling (for containers or non-systemd systems)

**Banaction options:**

- `iptables-multiport` (default) — stable, maximum compatibility
- `nftables-multiport` — modern, better performance on Ubuntu 22.04+ (requires nftables)

### SSH jail (dictionary)

```yaml
fail2ban_sshd:
  enabled: true
  port: ssh
  logpath: /var/log/auth.log  # ignored when backend=systemd
  maxretry: 5
  bantime: 3600
  findtime: 600
```

### Recidive jail (dictionary)

Bans IP addresses that have been banned multiple times:

```yaml
fail2ban_recidive:
  enabled: true
  banaction: "%(banaction_allports)s"
  logpath: /var/log/fail2ban.log
  maxretry: 3
  bantime: 604800    # 1 week
  findtime: 43200    # 12 hours
```

### Extra jails

Extra jails are created with the prefix `10-` in `/etc/fail2ban/jail.d/`:

- `10-nginx-http-auth.local`
- `10-postfix.local`

This prefix allows:

- Controlled load order of configurations
- **Safe removal of only Ansible-managed files**
- No conflicts with manual admin configs or package-provided files

```yaml
fail2ban_extra_jails:
  - name: nginx-http-auth
    enabled: true
    port: http,https
    logpath: /var/log/nginx/error.log
    maxretry: 5
    bantime: 7200
  - name: postfix
    enabled: true
    port: smtp,ssmtp
    logpath: /var/log/mail.log
```

### Cleanup

**Disabled by default** for safety. Enable explicitly:

```yaml
fail2ban_cleanup_enabled: true
```

This removes only files with prefix `10-` that are not in `fail2ban_extra_jails` or `10-sshd.local`.

## Dependencies

None.

## Example Playbook

```yaml
- hosts: webservers
  become: true
  roles:
    - role: fail2ban
      vars:
        # Ubuntu 22.04+ optimized configuration
        fail2ban_default:
          backend: systemd
          banaction: nftables-multiport
          bantime: 7200
          findtime: 600
          maxretry: 3
          bantime_increment: true
          bantime_factor: 1
          bantime_formula_enabled: true
          bantime_formula: "ban.Time * (1.0 + banFactor*log(1+banCount))"
          bantime_overalljails: true
          ignoreip:
            - 127.0.0.1/8
            - 10.0.0.0/8
        fail2ban_sshd:
          enabled: true
          port: ssh
          logpath: /var/log/auth.log
          maxretry: 3
          bantime: 7200
          findtime: 600
        fail2ban_recidive:
          enabled: true
          maxretry: 3
          bantime: 1209600  # 2 weeks
          findtime: 86400   # 1 day
        fail2ban_extra_jails:
          - name: nginx-http-auth
            logpath: /var/log/nginx/error.log
        fail2ban_cleanup_enabled: true
```

## Tags

| Tag | Description |
|---|---|
| `fail2ban` | Run all role tasks |
| `fail2ban_preflight` | Validation checks |
| `fail2ban_install` | Package installation |
| `fail2ban_config` | Configuration files |
| `fail2ban_service` | Service management |
| `fail2ban_cleanup` | Remove unmanaged jails |

## Handlers

This role provides two handlers:

- **`Restart fail2ban`** — full service restart (used for global config changes)
- **`Reload fail2ban`** — reload jails only (faster, used for jail config changes)

The role automatically selects the appropriate handler based on what changed.

## Testing & Idempotency

```bash
# Install dependencies
pip install molecule molecule-plugins[docker] ansible ansible-lint yamllint

# Run full test cycle (includes idempotence check by default)
molecule test

# Manual idempotency verification (CRITICAL)
molecule converge
molecule idempotence  # MUST return changed=0, failed=0
molecule verify

# Lint checks
ansible-lint
yamllint .
```

## License

MIT

## Author

Your Name

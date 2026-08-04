# Ansible Role: hardening

Роль безопасности для Ubuntu-серверов. Управляет SSH, sudo и sysctl security-параметрами на основе CIS Benchmark и STIG.

## Назначение

- SSH hardening через drop-in `/etc/ssh/sshd_config.d/99-hardening.conf`
- Sudo конфигурация через `/etc/sudoers.d/90-hardening`
- Sysctl security-параметры через `/etc/sysctl.d/99-hardening.conf`

**НЕ управляет:**
- Firewall (UFW/nftables) → роль `firewall`
- Intrusion prevention (fail2ban) → роль `fail2ban`
- Audit system (auditd) → роль `auditd`
- Пользователями → cloud-init/Packer
- Пакетами → роль `base`

## Requirements

- Ubuntu Server 22.04+
- Ansible 2.16+
- `become` privileges (root access)
- Роль `base` должна быть выполнена первой
- OpenSSH Server (устанавливается ролью при необходимости)
- sudo (устанавливается ролью при необходимости)
- systemd (обязательно, проверяется в preflight)

## Supported OS

- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 24.04 LTS (Noble)

## Compatibility

| OS | Version | Status |
|----|---------|--------|
| Ubuntu | 22.04 LTS (Jammy) | ✔ Supported |
| Ubuntu | 24.04 LTS (Noble) | ✔ Supported |
| Debian | 11+ | ✘ Unsupported |
| RHEL/CentOS | 8+ | ✘ Unsupported |
| Rocky/Alma | 8+ | ✘ Unsupported |
| Other | - | ✘ Unsupported |

**Note:** Эта роль разработана специально для Ubuntu Server 22.04+ с systemd и использует `sshd_config.d` drop-in файлы. Для других дистрибутивов требуется адаптация.

## Supported Features

- SSH hardening via OpenSSH drop-in (`sshd_config.d`)
- Sudo hardening via `sudoers.d`
- Sysctl kernel and network security parameters
- CIS Benchmark aligned defaults
- Configurable AllowUsers / AllowGroups / DenyUsers / DenyGroups
- Full `argument_specs` validation
- Molecule tested on Ubuntu 22.04 and 24.04 (with idempotence check)
- Fully idempotent
- Safe sysctl reload (only our config file, not system-wide)

## Role Variables

### Component toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `hardening_manage_ssh` | `true` | Управлять SSH |
| `hardening_manage_sudo` | `true` | Управлять sudo |
| `hardening_manage_sysctl` | `true` | Управлять sysctl |

### Service names

| Variable | Default | Description |
|----------|---------|-------------|
| `hardening_ssh_service_name` | `ssh` | Имя службы SSH |

### SSH hardening

| Variable | Default | Description |
|----------|---------|-------------|
| `hardening_ssh_permit_root_login` | `no` | Разрешить root |
| `hardening_ssh_password_authentication` | `no` | Аутентификация по паролю |
| `hardening_ssh_pubkey_authentication` | `yes` | Аутентификация по ключу |
| `hardening_ssh_x11_forwarding` | `no` | X11 forwarding |
| `hardening_ssh_client_alive_interval` | `300` | Keep-alive (сек) |
| `hardening_ssh_client_alive_count_max` | `3` | Пропущенные keep-alive |
| `hardening_ssh_max_auth_tries` | `4` | Максимум попыток |
| `hardening_ssh_permit_empty_passwords` | `no` | Пустые пароли |
| `hardening_ssh_challenge_response_authentication` | `no` | Challenge-response |
| `hardening_ssh_use_pam` | `yes` | PAM |
| `hardening_ssh_use_dns` | `no` | DNS lookup |
| `hardening_ssh_allow_agent_forwarding` | `no` | Agent forwarding |
| `hardening_ssh_allow_tcp_forwarding` | `no` | TCP forwarding |
| `hardening_ssh_gateway_ports` | `no` | Gateway ports |
| `hardening_ssh_print_motd` | `no` | Печатать MOTD |
| `hardening_ssh_print_last_log` | `yes` | Печатать последний вход |
| `hardening_ssh_tcp_keep_alive` | `yes` | TCP keep-alive |
| `hardening_ssh_compression` | `no` | Сжатие |
| `hardening_ssh_login_grace_time` | `60s` | Время на вход |
| `hardening_ssh_allow_users` | `[]` | Разрешённые пользователи |
| `hardening_ssh_allow_groups` | `[]` | Разрешённые группы |
| `hardening_ssh_deny_users` | `[]` | Запрещённые пользователи |
| `hardening_ssh_deny_groups` | `[]` | Запрещённые группы |

### Sudo configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `hardening_sudo_group` | `sudo` | Группа для sudo |
| `hardening_sudo_require_password` | `true` | Требовать пароль |
| `hardening_sudo_timestamp_timeout` | `15` | Timeout (мин) |
| `hardening_sudo_logfile` | `""` | Лог sudo (пусто = syslog) |
| `hardening_sudo_env_reset` | `true` | Сброс окружения |
| `hardening_sudo_use_pty` | `true` | Требовать PTY |
| `hardening_sudo_lecture` | `never` | Политика лекции (`never`/`once`/`always`) |

### Sysctl extra parameters

| Variable | Default | Description |
|----------|---------|-------------|
| `hardening_sysctl_extra_params` | `[]` | Дополнительные параметры (без дубликатов) |

## Dependencies

None.

## Example Playbook

### Базовый hardening

```yaml
- hosts: all
  become: yes
  roles:
    - role: hardening
```

### Для Kubernetes (с ip_forward)

```yaml
- hosts: k8s_nodes
  become: yes
  roles:
    - role: hardening
      vars:
        hardening_sysctl_extra_params:
          - { name: net.ipv4.ip_forward, value: 1 }
          - { name: net.bridge.bridge-nf-call-iptables, value: 1 }
          - { name: net.bridge.bridge-nf-call-ip6tables, value: 1 }
```

## Example Inventory

### `group_vars/k8s.yml`

```yaml
---
hardening_ssh_password_authentication: "no"
hardening_ssh_permit_root_login: "no"
hardening_sysctl_extra_params:
  - name: net.ipv4.ip_forward
    value: 1
  - name: net.bridge.bridge-nf-call-iptables
    value: 1
  - name: net.bridge.bridge-nf-call-ip6tables
    value: 1
```

### `group_vars/dmz.yml`

```yaml
---
hardening_ssh_allow_tcp_forwarding: "yes"
hardening_ssh_password_authentication: "yes"
```

### `group_vars/bastion.yml`

```yaml
---
hardening_ssh_allow_tcp_forwarding: "yes"
hardening_ssh_allow_agent_forwarding: "yes"
hardening_ssh_permit_root_login: "no"
```

## Tags

| Tag | Description |
|-----|-------------|
| `hardening` | Все задачи |
| `preflight` | Проверка ОС |
| `ssh` | SSH hardening |
| `sudo` | Sudo конфигурация |
| `sysctl` | Sysctl security |

Примеры:

```bash
# Только SSH
ansible-playbook site.yml --tags ssh

# SSH и sudo
ansible-playbook site.yml --tags ssh,sudo

# Пропустить sysctl
ansible-playbook site.yml --skip-tags sysctl
```

## ⚠️ Предупреждения

1. **SSH:** Перед запуском убедитесь, что у вас настроены SSH-ключи. Если `PasswordAuthentication no` и ключей нет — вы потеряете доступ.
2. **Validation:** SSH-конфигурация проверяется через `sshd -t` в handler перед reload. Битый конфиг не будет применён.
3. **Sudo:** Файл sudoers проверяется через `visudo -cf %s`. Синтаксические ошибки не будут применены.
4. **ACL conflicts:** Preflight проверяет пересечения между AllowUsers/DenyUsers и AllowGroups/DenyGroups. Конфликтующие конфигурации будут отклонены до применения.

## Применяемые sysctl параметры

### Network - Anti-spoofing
- `net.ipv4.conf.all.rp_filter = 1`
- `net.ipv4.conf.default.rp_filter = 1`

### Network - ICMP
- `net.ipv4.icmp_echo_ignore_broadcasts = 1`
- `net.ipv4.icmp_ignore_bogus_error_responses = 1`

### Network - Redirects and source routing
- `net.ipv4.conf.all.accept_redirects = 0`
- `net.ipv4.conf.default.accept_redirects = 0`
- `net.ipv4.conf.all.send_redirects = 0`
- `net.ipv4.conf.default.send_redirects = 0`
- `net.ipv4.conf.all.accept_source_route = 0`
- `net.ipv4.conf.default.accept_source_route = 0`
- `net.ipv6.conf.all.accept_redirects = 0`
- `net.ipv6.conf.default.accept_redirects = 0`
- `net.ipv6.conf.all.accept_source_route = 0`
- `net.ipv6.conf.default.accept_source_route = 0`

### Network - SYN flood protection
- `net.ipv4.tcp_syncookies = 1`

### Network - Logging
- `net.ipv4.conf.all.log_martians = 1`
- `net.ipv4.conf.default.log_martians = 1`

### Kernel - ASLR and core dumps
- `kernel.randomize_va_space = 2`
- `fs.suid_dumpable = 0`

### Kernel - Security
- `kernel.core_uses_pid = 1`
- `kernel.kptr_restrict = 2`
- `kernel.dmesg_restrict = 1`
- `kernel.perf_event_paranoid = 3`
- `kernel.yama.ptrace_scope = 1`

### File system
- `fs.protected_hardlinks = 1`
- `fs.protected_symlinks = 1`
- `fs.protected_fifos = 2`
- `fs.protected_regular = 2`

## Testing

```bash
# Запустить полные Molecule тесты (включая idempotence)
cd roles/hardening
molecule test

# Только converge (применение роли)
molecule converge

# Только verify (проверка результатов)
molecule verify

# Только idempotence (повторный запуск converge)
molecule idempotence

# Destroy тестовые контейнеры
molecule destroy
```

**Что проверяет `molecule test`:**
1. Создаёт Docker-контейнеры Ubuntu 22.04 и 24.04
2. Применяет роль (`converge`)
3. Запускает роль повторно и проверяет отсутствие изменений (`idempotence`)
4. Проверяет результаты через `sshd -T`, `sysctl`, `systemctl is-active ssh`, `visudo -cf` (`verify`)
5. Удаляет контейнеры (`destroy`)

## License

MIT

## Author Information

Создано для управления безопасностью Ubuntu-серверов в инфраструктуре.

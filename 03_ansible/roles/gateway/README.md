# Role: gateway

## Purpose
Настройка Linux-машины в качестве шлюза с NAT и IP forwarding.

Роль деплоит правила iptables через `iptables-restore` (атомарно, идемпотентно)
и использует нативный механизм `iptables-persistent` для сохранения правил
между перезагрузками.

## Requirements
- Ansible >= 2.14
- Коллекция `ansible.posix` (для модуля `sysctl`)
- Коллекция `ansible.utils` (для фильтра `ipaddr`)
- Целевая ОС: Ubuntu 22.04+ / Debian 11+

### Установка зависимостей

```bash
ansible-galaxy install -r collections/requirements.yml
```

## Variables

| Переменная                   | По умолчанию       | Описание                                       |
|------------------------------|--------------------|------------------------------------------------|
| `gateway_enabled`            | `true`             | Главный выключатель роли                       |
| `gateway_manage_forwarding`  | `true`             | Управлять ли sysctl (ip_forward)               |
| `gateway_manage_firewall`    | `true`             | Управлять ли iptables правилами                |
| `gateway_install_persistent` | `true`             | Устанавливать ли `iptables-persistent`         |
| `gateway_enable_logging`     | `false`            | Логировать ли дропнутые пакеты                 |
| `gateway_nat_enabled`        | `true`             | Включить NAT (MASQUERADE). `false` = router mode |
| `gateway_internal_network`   | `192.168.100.0/24` | Внутренняя сеть (CIDR, валидируется)           |
| `gateway_external_interface` | `eth0`             | Внешний интерфейс                              |
| `gateway_internal_interface` | `eth1`             | Внутренний интерфейс                           |
| `gateway_extra_filter_rules` | `[]`               | Дополнительные правила для таблицы filter      |
| `gateway_extra_nat_rules`    | `[]`               | Дополнительные правила для таблицы nat         |

## Security Model
- **INPUT**: Не изменяется ролью.
- **OUTPUT**: Не изменяется ролью.
- **FORWARD**: По умолчанию `DROP`. Разрешается:
  - `RELATED,ESTABLISHED` — обратный трафик.
  - `NEW` с внутреннего интерфейса на внешний для указанной сети.
- **NAT**: `MASQUERADE` только для `gateway_internal_network` на внешний интерфейс.
  Отключается через `gateway_nat_enabled: false`.

## Safe Deployment

Роль использует двухфазный деплой правил iptables:

1. Шаблон рендерится во временный файл (`/tmp/.rules.v4.gateway.tmp`).
2. Выполняется `iptables-restore --test` для проверки синтаксиса.
3. Только после успешной проверки файл атомарно копируется в `/etc/iptables/rules.v4`.
4. Handler применяет правила через `netfilter-persistent reload`.

Если шаблон содержит ошибки, рабочий файл `/etc/iptables/rules.v4` остаётся нетронутым,
и система сохраняет текущий firewall даже после перезагрузки.

## Extending rules

> ⚠️ **Important:** Rules in `gateway_extra_filter_rules` and `gateway_extra_nat_rules`
> must **not** contain table headers (`*filter`, `*nat`) or `COMMIT` statements.
> These are managed by the template itself.

```yaml
gateway_extra_filter_rules:
  - "-A FORWARD -p tcp -s 192.168.100.50 --dport 22 -j ACCEPT"

gateway_extra_nat_rules:
  - "-A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-port 80"
```

## Known Limitations

- **INPUT chain**: Намеренно не управляется ролью (настраивается через `hardening`)
- **OUTPUT chain**: Намеренно не управляется ролью
- **IPv6**: Не поддерживается (только IPv4)
- **nftables backend**: Не реализован (используется legacy iptables)
- **Firewalld**: Не поддерживается как альтернативный backend

## Handlers

| Handler            | Описание                                            |
|--------------------|-----------------------------------------------------|
| `Apply firewall`   | Перезапускает `netfilter-persistent`                |

Вызывается автоматически при изменении `/etc/iptables/rules.v4`.
Перед запуском `verify.yml` выполняется `meta: flush_handlers`.

## Tags

| Тег                    | Описание                                        |
|------------------------|-------------------------------------------------|
| `gateway-preflight`    | Проверка ОС, интерфейсов, CIDR (always)         |
| `gateway-install`      | Установка пакетов                               |
| `gateway-forwarding`   | Настройка sysctl (ip_forward)                   |
| `gateway-firewall`     | Деплой правил iptables                          |
| `gateway-verify`       | Assert-проверки состояния (для CI)              |
| `gateway-debug`        | Человекочитаемый summary (для ручного запуска)  |

## Example Playbook

```yaml
- hosts: router-prod-01
  become: yes
  roles:
    - role: base
    - role: hardening
    - role: gateway
```

### Переопределение переменных

В `host_vars/router-prod-01.yml`:
```yaml
gateway_external_interface: "ens18"
gateway_internal_interface: "ens19"
gateway_internal_network: "10.0.100.0/24"
```

### Router без NAT
```yaml
gateway_nat_enabled: false
gateway_manage_forwarding: true
```

### С дополнительными правилами
```yaml
gateway_extra_filter_rules:
  - "-A FORWARD -p tcp -s 192.168.100.50 --dport 22 -j ACCEPT"

gateway_extra_nat_rules:
  - "-A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-port 80"
```

## Usage Examples

```bash
# Полный прогон
ansible-playbook playbooks/site.yml

# Только пересоздать правила iptables
ansible-playbook playbooks/site.yml --tags gateway-firewall

# Assert-проверки состояния (для CI)
ansible-playbook playbooks/site.yml --tags gateway-verify

# Человекочитаемый summary (для ручного запуска)
ansible-playbook playbooks/site.yml --tags gateway-debug

# Пропустить роль полностью
ansible-playbook playbooks/site.yml -e "gateway_enabled=false"

# Настроить только forwarding (без фаервола)
ansible-playbook playbooks/site.yml -e "gateway_manage_firewall=false"
```

## Testing

Роль покрыта Molecule-тестами:

```bash
# Базовый сценарий (NAT + forwarding)
cd roles/gateway
molecule test -s default

# Router mode (без NAT)
molecule test -s router

# С логированием
molecule test -s logging

# Негативные тесты (невалидные входные данные)
molecule test -s broken
```

## Future Improvements

- [ ] Поддержка IPv6 (rules.v6)
- [ ] **nftables backend** (приоритет: Debian 13 / Ubuntu 24.04+ живут поверх nft)
- [ ] Legacy iptables backend (поддержка старых систем)
- [ ] Hairpin NAT (обращение к внешнему IP из внутренней сети)
- [ ] Port forwarding через декларативную переменную `gateway_port_forwards`
- [ ] SNAT (фиксированный внешний IP вместо MASQUERADE)
- [ ] Policy routing (несколько uplink-интерфейсов)

# Ansible Role: resolver

## Purpose
Управление конфигурацией DNS-клиента на Ubuntu-серверах с использованием Netplan drop-in файлов. Роль гарантирует четкое разделение ответственности: базовая сеть (IP, шлюзы, маршруты) управляется через Cloud-init/Terraform, а DNS-настройки — через эту роль.

## Supported Ubuntu
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

Роль **не поддерживается** на Ubuntu 18.04/20.04 и других дистрибутивах.

## Architecture

```
Terraform
      │
      ▼
Cloud-init
      │
      ▼
50-cloud-init.yaml  ──── IP, Gateway, Routes
      │
──────────────────────────────────────────
      │
Ansible (роль resolver)
      │
      ▼
99-ansible-resolver.yaml  ──── DNS, Search Domains
      │
      ▼
netplan (deep merge)
      │
      ▼
systemd-networkd
      │
      ▼
systemd-resolved
      │
      ▼
/etc/resolv.conf (генерируется автоматически)
```

Каждый компонент отвечает только за свою область:
- **Terraform / Cloud-init** — базовая сетевая конфигурация (L3).
- **Ansible (resolver)** — DNS-клиент (имена, поиск).
- **Netplan** — объединение конфигураций и применение.

## Requirements
- ОС: Ubuntu 22.04+ (с поддержкой Netplan и systemd-resolved)
- Коллекция Ansible: `ansible.utils` (устанавливается из корневого `collections/requirements.yml` проекта)
- Привилегии: `become: true`

## Variables
| Переменная | Тип | По умолчанию | Описание |
|------------|-----|--------------|----------|
| `resolver_state` | str | `present` | Состояние: `present` (настроить) или `absent` (удалить конфигурацию) |
| `resolver_nameservers` | list | `[]` | Список IPv4/IPv6 адресов DNS-серверов |
| `resolver_search_domains` | list | `[]` | Список доменов поиска DNS |
| `resolver_dns_verification_host` | str | `""` | Хост для проверки работы DNS (должен гарантированно существовать) |
| `resolver_verify_external` | bool | `false` | Проверять ли разрешение внешних имен (например, github.com) |

## Example
```yaml
- hosts: ubuntu_servers
  roles:
    - role: resolver
      vars:
        resolver_state: present
        resolver_nameservers:
          - "192.168.100.53"
          - "192.168.100.54"
        resolver_search_domains:
          - "local.lab"
        resolver_dns_verification_host: "dns.local.lab"
```

## Verification
После применения роли выполните:
1. `netplan get` — убедитесь, что IP/маршруты и nameservers объединены корректно.
2. `resolvectl dns <interface>` — проверьте назначенные DNS-серверы.
3. `resolvectl domain <interface>` — проверьте назначенные домены поиска.
4. `resolvectl query <verification_host>` — убедитесь в успешном разрешении имен.

## Limitations
- Роль предназначена исключительно для систем, где рендерером по умолчанию является `systemd-networkd`.
- **Важно:** Механизм слияния (merge) конфигураций Netplan поддерживает глубокое объединение словарей, но поведение отдельных ключей (например, списков) зависит от конкретной версии Netplan. Данная архитектура безопасна при условии, что поведение подтверждено тестами на целевых версиях Ubuntu (22.04, 24.04), используемых в проекте.
- Для использования `state: absent` убедитесь, что базовая конфигурация (например, из `50-cloud-init.yaml`) содержит все необходимые сетевые параметры для работоспособности хоста.

## TODO
- [ ] Реализовать Molecule-тесты после перехода на драйвер `libvirt` / `vagrant` / `proxmox`. Docker-драйвер не подходит, так как в контейнерах отсутствует полноценный systemd, netplan и systemd-resolved, что делает тесты некорректными.

# Ansible Role: DNS (BIND9)

Устанавливает и настраивает BIND9 в качестве авторитативного и рекурсивного DNS-сервера.

## Requirements
- **OS**: Ubuntu 22.04 (Jammy) / 24.04 (Noble)
- **Ansible**: >= 2.16
- **Privileges**: `become: yes` (root)

## Архитектура роли

```text
DNS Role
├── Preflight     : Проверка совместимости ОС (Ubuntu 22.04+) и systemd
├── Install       : Установка пакетов (bind9, bind9utils, dnsutils)
├── Configure     : Развертывание named.conf.options и named.conf.local
├── Zones         : Генерация файлов прямой и обратной зон из шаблонов
├── Service       : Управление состоянием сервиса (enabled/started)
├── Handlers      : Graceful reload сервиса при изменении конфигов
└── Validate      : Проверка синтаксиса (named-checkconf/zone), порта 53 и функциональности (dig)

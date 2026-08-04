# Base Role

Эта роль выполняет базовую подготовку любой новой Ubuntu-машины перед применением специализированных ролей (hardening, docker, rke2 и т.д.).

## Возможности
- **Preflight**: Проверка DNS и TCP-доступа в интернет до начала изменений.
- **Packages**: Установка базового набора утилит (включая сетевые и диагностические).
- **Time & Locale**: Настройка часового пояса и генерация локали.
- **Chrony**: Настройка синхронизации времени через NTP.
- **QEMU**: Автоматическая установка и запуск `qemu-guest-agent` (только для ВМ).
- **Sysctl**: Применение безопасных базовых настроек ядра.
- **MOTD**: Красивый информационный баннер при входе в систему.

## Переменные (defaults/main.yml)
Все переменные имеют префикс `base_`. Их можно переопределить в `group_vars` или `host_vars`.

Пример для `group_vars/production.yml`:
```yaml
base_timezone: "Asia/Almaty"
base_ntp_servers:
  - dc-prod-01.local.lab
base_motd_environment: "Production"
base_motd_role: "DNS Server"

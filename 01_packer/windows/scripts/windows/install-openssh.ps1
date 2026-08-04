# Установка OpenSSH Server
Write-Host "Installing OpenSSH Server..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Настройка sshd_config
$sshdConfig = @"
Port 22
ListenAddress 0.0.0.0

# Host keys (без дублей)
HostKey __PROGRAMDATA__/ssh/ssh_host_rsa_key
HostKey __PROGRAMDATA__/ssh/ssh_host_ecdsa_key
HostKey __PROGRAMDATA__/ssh/ssh_host_ed25519_key

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication
PubkeyAuthentication yes
PasswordAuthentication yes
# StrictModes no

# Для обычных пользователей — ключи в профиле
AuthorizedKeysFile .ssh/authorized_keys

# Security
IgnoreRhosts yes
HostbasedAuthentication no
PermitEmptyPasswords no

# Subsystem
Subsystem sftp sftp-server.exe

# Для администраторов — ключи в ProgramData (стандарт Windows), отключил потому-что создаю пользователя ansible с ключем в c:\users\ansible\.ssh
# Match Group administrators
#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
"@

# Записываем файл корнфигурации
$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
Set-Content -Path $sshdConfigPath -Value $sshdConfig -Encoding ASCII

# Настройка прав на файл ключей (КРИТИЧНО!) - ключ через Packer не нужно вставлять
# icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r
# icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /grant:r SYSTEM:F /grant:r BUILTIN\Administrators:F

# Разрешаем UAC и PowerShell over SSH для Anisble
# 1. Меняем дефолтную оболочку для SSH с cmd.exe на PowerShell
# Для стандартного Windows PowerShell 5.1:
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# 2. Отключаем ограничение UAC для удаленных администраторов (Решает проблему Access is denied)
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -PropertyType DWord -Force

# Запуск службы
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Firewall правило
# При установке OpenSSH правило создается автоматически
# Это ручное правило можно пропустить
#New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
#    -DisplayName "OpenSSH Server (sshd)" `
#    -Enabled True `
#    -Direction Inbound `
#    -Protocol TCP `
#    -Action Allow `
#    -LocalPort 22


Write-Host "OpenSSH Server installed and configured."

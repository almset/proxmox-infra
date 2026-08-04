# ============================================
# Install monitoring agents on Windows
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INSTALLING MONITORING AGENTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================
# Configuration
# ============================================
$ZABBIX_SERVER = "zabbix.corp.local"
$ZABBIX_VERSION = "7.4"
$WINDOWS_EXPORTER_VERSION = "0.31.7"

# ============================================
# 1. Install Zabbix Agent
# ============================================
Write-Host "`n[1/3] Installing Zabbix Agent..." -ForegroundColor Yellow

try {
    $zabbixDownloadUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/${ZABBIX_VERSION}/${ZABBIX_VERSION}.9/zabbix_agent-${ZABBIX_VERSION}.9-windows-amd64-openssl.msi"
    $zabbixInstaller = "$env:TEMP\zabbix_agent.msi"

    Write-Host "  Downloading Zabbix Agent from: $zabbixDownloadUrl"
    Invoke-WebRequest -Uri $zabbixDownloadUrl -OutFile $zabbixInstaller -ErrorAction Stop

    Write-Host "  Installing Zabbix Agent..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$zabbixInstaller`" /quiet /norestart SERVER=$ZABBIX_SERVER SERVERACTIVE=$ZABBIX_SERVER HOSTNAME=$env:COMPUTERNAME" -Wait

    Write-Host "  [OK] Zabbix Agent installed"
} catch {
    Write-Host "  [WARN] Zabbix Agent installation failed: $_" -ForegroundColor Red
    Write-Host "  [INFO] Continue with other monitoring tools" -ForegroundColor Yellow
}

# ============================================
# 2. Install Windows Exporter (Prometheus)
# ============================================
Write-Host "`n[2/3] Installing Windows Exporter..." -ForegroundColor Yellow

try {
    $exporterUrl = "https://github.com/prometheus-community/windows_exporter/releases/download/v${WINDOWS_EXPORTER_VERSION}/windows_exporter-${WINDOWS_EXPORTER_VERSION}-amd64.msi"
    $exporterInstaller = "$env:TEMP\windows_exporter.msi"

    Write-Host "  Downloading Windows Exporter from: $exporterUrl"
    Invoke-WebRequest -Uri $exporterUrl -OutFile $exporterInstaller -ErrorAction Stop

    Write-Host "  Installing Windows Exporter..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$exporterInstaller`" /quiet /norestart ENABLED_COLLECTORS=cpu,cs,logical_disk,net,os,service,system,textfile" -Wait

    Write-Host "  [OK] Windows Exporter installed"
} catch {
    Write-Host "  [WARN] Windows Exporter installation failed: $_" -ForegroundColor Red
}

# ============================================
# 3. Install Wazuh Agent (optional)
# ============================================
Write-Host "`n[3/3] Installing Wazuh Agent..." -ForegroundColor Yellow

$WAZUH_MANAGER = "wazuh.corp.local"
$WAZUH_VERSION = "4.7.0"

try {
    $wazuhUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-${WAZUH_VERSION}-1.msi"
    $wazuhInstaller = "$env:TEMP\wazuh-agent.msi"

    Write-Host "  Downloading Wazuh Agent..."
    Invoke-WebRequest -Uri $wazuhUrl -OutFile $wazuhInstaller -ErrorAction Stop

    Write-Host "  Installing Wazuh Agent..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$wazuhInstaller`" /quiet /norestart WAZUH_MANAGER=$WAZUH_MANAGER WAZUH_REGISTRATION_SERVER=$WAZUH_MANAGER WAZUH_AGENT_NAME=$env:COMPUTERNAME" -Wait

    Write-Host "  [OK] Wazuh Agent installed"
} catch {
    Write-Host "  [WARN] Wazuh Agent installation skipped: $_" -ForegroundColor Yellow
}

# ============================================
# Configure firewall for monitoring
# ============================================
Write-Host "`nConfiguring firewall for monitoring..." -ForegroundColor Yellow

# Zabbix Agent (10050/tcp)
New-NetFirewallRule -DisplayName "Zabbix Agent" -Direction Inbound -LocalPort 10050 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Windows Exporter (9182/tcp)
New-NetFirewallRule -DisplayName "Windows Exporter" -Direction Inbound -LocalPort 9182 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Wazuh Agent (1514-1515/udp/tcp)
New-NetFirewallRule -DisplayName "Wazuh Agent" -Direction Inbound -LocalPort 1514,1515 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

Write-Host "  [OK] Firewall rules added"

# ============================================
# Installation status
# ============================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  MONITORING AGENTS INSTALLATION SUMMARY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$services = @(
    @{Name="Zabbix Agent"; Service="Zabbix Agent"},
    @{Name="Windows Exporter"; Service="windows_exporter"},
    @{Name="Wazuh Agent"; Service="WazuhSvc"}
)

foreach ($svc in $services) {
    $status = Get-Service -Name $svc.Service -ErrorAction SilentlyContinue
    if ($status) {
        Write-Host "  [OK] $($svc.Name): $($status.Status)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $($svc.Name): Not installed" -ForegroundColor Yellow
    }
}

Write-Host "`n[INFO] To use Zabbix, update ZABBIX_SERVER variable with your server address" -ForegroundColor Cyan
Write-Host "[INFO] To use Wazuh, update WAZUH_MANAGER variable with your server address" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green

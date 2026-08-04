# infra/scripts/windows/initial-setup.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WINDOWS INITIAL SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$global:rebootNeeded = $false

# ============================================
# 1. Basic system settings
# ============================================
Write-Host "[1/6] Applying basic system settings..." -ForegroundColor Yellow

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
Write-Host "  [OK] UAC disabled"

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUsername" -Value "Administrator"
Write-Host "  [OK] AutoLogon configured"

powercfg -change -standby-timeout-ac 0
powercfg -change -hibernate-timeout-ac 0
Write-Host "  [OK] Power settings configured"

# ============================================
# 2. Network settings
# ============================================
Write-Host "[2/6] Configuring network settings..." -ForegroundColor Yellow

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Write-Host "  [OK] RDP enabled"

try {
    $tcpSetting = Get-NetTCPSetting -SettingName InternetCustom -ErrorAction SilentlyContinue
    if ($tcpSetting) {
        Set-NetTCPSetting -SettingName InternetCustom -CongestionProvider CTCP
        Set-NetTCPSetting -SettingName InternetCustom -CwndRestart True
        Write-Host "  [OK] TCP/IP optimized for virtualization"
    } else {
        Write-Host "  [SKIP] TCP/IP optimization skipped (InternetCustom not found)"
    }
} catch {
    Write-Host "  [WARN] TCP/IP optimization failed: $_"
}

# ============================================
# 3. Core components
# ============================================
Write-Host "[3/6] Installing core components..." -ForegroundColor Yellow

$features = @(
    @{Name="NET-Framework-Features"; NeedReboot=$true},
    @{Name="RSAT-AD-PowerShell"; NeedReboot=$false},
    @{Name="RSAT-AD-AdminCenter"; NeedReboot=$false}
)

foreach ($feature in $features) {
    try {
        $result = Install-WindowsFeature -Name $feature.Name -IncludeAllSubFeature -IncludeManagementTools -ErrorAction Stop
        if ($result.RestartNeeded -and $feature.NeedReboot) {
            $global:rebootNeeded = $true
            Write-Host "  [WARN] $($feature.Name) requires reboot (will reboot at end)"
        }
        Write-Host "  [OK] $($feature.Name) installed"
    } catch {
        Write-Host "  [WARN] $($feature.Name) installation failed: $_"
    }
}

# ============================================
# 4. Windows Update
# ============================================
Write-Host "[4/6] Configuring Windows Update..." -ForegroundColor Yellow

try {
    $wuRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (-not (Test-Path $wuRegPath)) {
        New-Item -Path $wuRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $wuRegPath -Name "AUOptions" -Value 4
    Set-ItemProperty -Path $wuRegPath -Name "ScheduledInstallDay" -Value 0
    Set-ItemProperty -Path $wuRegPath -Name "ScheduledInstallTime" -Value 3
    Write-Host "  [OK] Windows Update configured"
} catch {
    Write-Host "  [WARN] Windows Update configuration failed: $_"
}

# ============================================
# 5. Auditing and logging
# ============================================
Write-Host "[5/6] Configuring auditing..." -ForegroundColor Yellow

try {
    auditpol /set /subcategory:"Logon" /success:enable /failure:enable
    auditpol /set /subcategory:"File System" /success:enable /failure:enable
    auditpol /set /subcategory:"Sensitive Privilege Use" /success:enable /failure:enable
    Write-Host "  [OK] Auditing configured"
} catch {
    Write-Host "  [WARN] Audit configuration failed: $_"
}

# FIX: wevtutil требует отдельные вызовы с правильным синтаксисом
try {
    wevtutil sl "Application" /ms:10485760
    wevtutil sl "Security"    /ms:10485760
    wevtutil sl "System"      /ms:10485760
    Write-Host "  [OK] Event log size configured"
} catch {
    Write-Host "  [WARN] Event log configuration failed: $_"
}

# ============================================
# 6. Cleanup
# ============================================
Write-Host "[6/6] Cleanup and finalization..." -ForegroundColor Yellow

$tempPaths = @(
    "$env:TEMP",
    "C:\Windows\Temp"
)

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        try {
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cleaned: $path"
        } catch {
            Write-Host "  [WARN] Could not clean all files in $path"
        }
    }
}

try {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Host "  [OK] Windows Update cache cleaned"
} catch {
    Write-Host "  [WARN] Windows Update cache cleanup failed: $_"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "INITIAL SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# FIX: reboot через shutdown вместо Restart-Computer
# Packer успеет получить exit 0 до того как машина уйдёт в ребут
#if ($global:rebootNeeded) {
#    Write-Host "[INFO] Reboot required - scheduling shutdown in 10 seconds..." -ForegroundColor Yellow
#    shutdown /r /t 10 /f
#}

exit 0


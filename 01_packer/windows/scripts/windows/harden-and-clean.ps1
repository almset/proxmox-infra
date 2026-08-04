# infra/scripts/windows/harden-and-clean.ps1
# Security hardening and cleanup before sysprep

Write-Host "[Hardening] Starting security configuration..." -ForegroundColor Cyan

# === Disable unnecessary services ===
$servicesToDisable = @(
    "PrintSpooler",
    "RemoteRegistry",
    "WSearch",
    "XblGameSave",
    "DiagTrack"
)

foreach ($svc in $servicesToDisable) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled
        Write-Host "[Service] Disabled: $svc" -ForegroundColor Gray
    }
}

# === Audit policy ===
#auditpol /set /category:"Logon/Logoff" /subcategory:"Logon" /success:enable /failure:enable /quiet
#auditpol /set /category:"Object Access" /subcategory:"File System" /success:enable /failure:enable /quiet
#auditpol /set /category:"Privilege Use" /subcategory:"Sensitive Privilege Use" /success:enable /failure:enable /quiet
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"File System" /success:enable /failure:enable
auditpol /set /subcategory:"Sensitive Privilege Use" /success:enable /failure:enable
Write-Host "[Audit] Audit policies configured" -ForegroundColor Gray

# === Disable SMBv1 ===
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -Remove -NoRestart -ErrorAction SilentlyContinue
Write-Host "[Security] SMBv1 disabled" -ForegroundColor Gray

# === PowerShell Script Block Logging ===
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -Value 1
Set-ItemProperty -Path $regPath -Name "EnableModuleLogging" -Value 1
Write-Host "[Security] PowerShell logging enabled" -ForegroundColor Gray

# === Cleanup temp files ===
Write-Host "[Cleanup] Removing temporary files..." -ForegroundColor Yellow

$paths = @(
    "$env:TEMP\*",
    "$env:TMP\*",
    "C:\Windows\Temp\*",
    "C:\Windows\SoftwareDistribution\Download\*"
)

foreach ($path in $paths) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "[Cleanup] Temp files removed" -ForegroundColor Gray

# === Clear event logs ===
Write-Host "[Cleanup] Clearing event logs..." -ForegroundColor Yellow
wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }
Write-Host "[Cleanup] Event logs cleared" -ForegroundColor Gray

# === Component store cleanup ===
Write-Host "[Cleanup] Running DISM component cleanup..." -ForegroundColor Yellow
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase /NoRestart /Quiet
Write-Host "[Cleanup] Component store cleaned" -ForegroundColor Gray

# === Clear pagefile (reduce image size) ===
Write-Host "[Cleanup] Clearing pagefile settings..." -ForegroundColor Yellow
$pagefile = Get-WmiObject Win32_PageFileSetting
if ($pagefile) {
    $pagefile.InitialSize = 0
    $pagefile.MaximumSize = 0
    $pagefile.Put() | Out-Null
}
Write-Host "[Cleanup] Pagefile cleared (will be recreated after sysprep)" -ForegroundColor Gray

Write-Host ""
Write-Host "========================================"  -ForegroundColor Green
Write-Host "HARDENING AND CLEANUP COMPLETED" -ForegroundColor Green
Write-Host "========================================"  -ForegroundColor Green

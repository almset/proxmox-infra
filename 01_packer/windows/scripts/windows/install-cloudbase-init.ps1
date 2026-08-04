# Скачивание и установка Cloudbase-Init
$msiUrl = "https://github.com/cloudbase/cloudbase-init/releases/download/1.1.8/CloudbaseInitSetup_1_1_8_x64.msi"
$msiFile = "$env:TEMP\CloudbaseInitSetup_1_1_8_x64.msi"
Invoke-WebRequest -Uri $msiUrl -OutFile $msiFile -UseBasicParsing

Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiFile`" /qn /norestart INJECTMETADATAPASSWORD=0" -Wait
#start-Process msiexec.exe -ArgumentList "/i", $msiFile, "/qn", "/norestart" "INJECTMETADATAPASSWORD=0" -Wait

# Остановка службы (запустится при первом запуске ВМ)
Set-Service cloudbase-init -StartupType Automatic
Stop-Service cloudbase-init -Force -ErrorAction SilentlyContinue

Write-Host "Cloudbase-Init installed."

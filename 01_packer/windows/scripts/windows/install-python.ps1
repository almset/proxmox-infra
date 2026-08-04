$ErrorActionPreference = "Stop"

$pythonVersion = "3.13.7"
$url = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-amd64.exe"

$temp = "$env:TEMP\python-installer.exe"

Write-Host "Downloading Python..."
Invoke-WebRequest -Uri $url -OutFile $temp

Write-Host "Installing Python..."

Start-Process `
    -FilePath $temp `
    -ArgumentList @(
        "/quiet",
        "InstallAllUsers=1",
        "PrependPath=1",
        "Include_test=0",
        "Include_launcher=1",
        "SimpleInstall=1"
    ) `
    -Wait

Remove-Item $temp -Force

$env:Path += ";C:\Program Files\Python313;C:\Program Files\Python313\Scripts"

python --version
pip --version

Write-Host "Python installation completed."

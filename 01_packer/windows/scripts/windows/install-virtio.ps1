# infra/scripts/windows/install-virtio.ps1
# Install VirtIO drivers

Write-Host "Installing VirtIO drivers..." -ForegroundColor Green

$driveLetter = (Get-Volume -FileSystemLabel "VirtIO").DriveLetter
if (-not $driveLetter) {
    Write-Host "VirtIO drive not found" -ForegroundColor Red
    exit 1
}

$driverPath = "${driveLetter}:\"

# Install Balloon driver
pnputil /add-driver "$driverPath\Balloon\2k19\amd64\*.inf" /install
# Install NetKVM driver
pnputil /add-driver "$driverPath\NetKVM\2k19\amd64\*.inf" /install
# Install vioscsi driver
pnputil /add-driver "$driverPath\vioscsi\2k19\amd64\*.inf" /install
# Install viostor driver
pnputil /add-driver "$driverPath\viostor\2k19\amd64\*.inf" /install

Write-Host "VirtIO drivers installed" -ForegroundColor Green

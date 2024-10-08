# Ensure machine is on the 192.168.10.0/28 network with gateway 192.168.10.1
$interface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
if ($interface) {
    Write-Host "Setting static IP for $($interface.Name)..."
    New-NetIPAddress -InterfaceAlias $interface.Name -IPAddress "192.168.10.2" -PrefixLength 28 -DefaultGateway "192.168.10.1" -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses "192.168.10.1"
} else {
    Write-Host "No active network adapter found. Ensure you have the correct interface up."
    exit 1
}

# Install NuGet provider and PowerShellGet module
Install-PackageProvider -Name Nuget -Force
Install-Module -Name PowerShellGet -Force

# Set Security Protocol to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create C:\Setup directory if it does not exist
if (!(Test-Path -Path 'C:\\Setup')) {
    New-Item -Path 'C:\\Setup' -ItemType Directory
    Write-Host 'Created C:\\Setup directory.'
} else {
    Write-Host 'C:\\Setup directory already exists.'
}

# Download the file using Invoke-WebRequest with retries
$url = 'http://192.168.254.51/CloudbaseInitSetup_Stable_x64.msi'
$outFile = 'C:\\Setup\\CloudbaseInitSetup_Stable_x64.msi'
$maxRetries = 5
$retryInterval = 30  # Wait time (in seconds) between retries
$success = $false

for ($i = 0; $i -lt $maxRetries; $i++) {
    try {
        Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing -ErrorAction Stop
        $success = $true
        break  # Exit loop if successful
    } catch {
        Write-Host "Download attempt $($i + 1) failed. Retrying in $retryInterval seconds..."
        Start-Sleep -Seconds $retryInterval
    }
}

if (-not $success) {
    Write-Host "Failed to download after $maxRetries attempts."
    exit 1  # Exit with error if all attempts fail
} else {
    Write-Host "Successfully downloaded CloudbaseInitSetup_Stable_x64.msi to C:\\Setup"
}

# Verify file size to ensure full download
$expectedSize = 69267456  # Replace this with the actual size of your file in bytes
$actualSize = (Get-Item $outFile).Length

if ($actualSize -eq $expectedSize) {
    Write-Host "File download verified. Size is correct."
} else {
    Write-Host "File download incomplete. Expected $expectedSize bytes, but got $actualSize bytes."
    exit 1  # Exit with error if the file size doesn't match
}

# Set a specific DNS server for 'Ethernet 0 2' adapter
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 0 2' -ServerAddresses ('192.168.10.1')

# Configure proxy settings (adjust 'proxy-server:port' to your needs)
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyServer -Value 'proxy-server:port'
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 1

Write-Host "Network and system configurations are complete."

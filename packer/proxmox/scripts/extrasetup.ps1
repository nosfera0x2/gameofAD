# Check and install PowerShellGet if needed
if ((Get-Module -ListAvailable -Name PowerShellGet).Version -lt '2.0.0') { 
    Install-Module -Name PowerShellGet -Force 
}

# Check and install NuGet Package Provider if needed
if ((Get-PackageProvider -ListAvailable -Name NuGet).Version -lt '2.8.5.201') { 
    Install-PackageProvider -Name NuGet -Force 
}

# Set Security Protocol to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Force installation of NuGet and PowerShellGet
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module PowerShellGet -Force

# Set all network adapters to use DHCP and reset DNS server addresses
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    Set-NetIPInterface -InterfaceAlias $_.Name -Dhcp Enabled
    Set-DnsClientServerAddress -InterfaceAlias $_.Name -ResetServerAddresses
}

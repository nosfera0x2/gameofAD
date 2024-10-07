Install-PackageProvider -Name Nuget -Force

Install-Module -Name PowerShellGet -Force

# Set Security Protocol to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set all network adapters to use DHCP and reset DNS server addresses
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    Set-NetIPInterface -InterfaceAlias $_.Name -Dhcp Enabled
    Set-DnsClientServerAddress -InterfaceAlias $_.Name -ResetServerAddresses
}

# Set a specific DNS server for 'Ethernet 0 2' adapter
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 0 2' -ServerAddresses ('192.168.10.1')

# Configure proxy settings
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyServer -Value 'proxy-server:port'
Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 1

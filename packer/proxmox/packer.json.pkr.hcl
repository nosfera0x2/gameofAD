
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "windows" {
  additional_iso_files {
    device           = "sata3"
    iso_checksum     = "${var.autounattend_checksum}"
    iso_storage_pool = "local"
    iso_url          = "${var.autounattend_iso}"
    unmount          = true
  }
  additional_iso_files {
    device   = "sata4"
    iso_file = "local:iso/virtio-win.iso"
    unmount  = true
  }
  additional_iso_files {
    device   = "sata5"
    iso_file = "local:iso/scripts_withcloudinit.iso"
    unmount  = true
  }
  cloud_init              = true
  cloud_init_storage_pool = "${var.proxmox_iso_storage}"
  communicator            = "winrm"
  cores                   = "${var.vm_cpu_cores}"
  disks {
    disk_size         = "${var.vm_disk_size}"
    format            = "${var.vm_disk_format}"
    storage_pool      = "${var.proxmox_vm_storage}"
    type              = "sata"
  }
  insecure_skip_tls_verify = "${var.proxmox_skip_tls_verify}"
  iso_file                 = "${var.iso_file}"
  memory                   = "${var.vm_memory}"
  network_adapters {
    bridge = "vmbr0"
    model  = "e1000"
    vlan_tag = "20"
  }
  node                 = "${var.proxmox_node}"
  os                   = "${var.os}"
  password             = "${var.proxmox_password}"
  pool                 = "${var.proxmox_pool}"
  proxmox_url          = "${var.proxmox_url}"
  sockets              = "${var.vm_sockets}"
  template_description = "${var.template_description}"
  template_name        = "${var.vm_name}"
  username             = "${var.proxmox_username}"
  vm_name              = "${var.vm_name}"
  winrm_insecure       = true
  winrm_no_proxy       = true
  winrm_password       = "${var.winrm_password}"
  winrm_timeout        = "120m"
  winrm_use_ssl        = true
  winrm_username       = "${var.winrm_username}"
  task_timeout         = "40m"
}

build {
  sources = ["source.proxmox-iso.windows"]

    # Ensure WinRM is configured properly
  provisioner "powershell" {
    inline = [
      "winrm quickconfig -quiet",
      "winrm set winrm/config/service/Auth @{Basic='true'}",
      "winrm set winrm/config/service @{AllowUnencrypted='false'}",  # Use HTTPS
      "winrm set winrm/config/Service @{MaxMemoryPerShellMB='1024'}",
      "winrm set winrm/config/winrs @{MaxProcessesPerShell='25'}",
      "winrm set winrm/config @{MaxConcurrentOperationsPerUser='25'}",
      "winrm set winrm/config @{MaxTimeoutms='1800000'}",  # 30-minute timeout for WinRM
      "winrm set winrm/config @{MaxEnvelopeSizekb='5000'}",  # Max envelope size to 5MB
      "New-NetFirewallRule -Name 'Allow WinRM HTTPS' -Protocol TCP -LocalPort 5986 -Action Allow"
    ]
  }

  # Optional: Add a small delay before uploading the file to stabilize WinRM connection
  provisioner "powershell" {
    inline = ["Start-Sleep -Seconds 60"]
    pause_before = "60s"
  }
  provisioner "file" {
    source      = "/root/gameofAD/packer/proxmox/scripts/sysprep/CloudbaseInitSetup_Stable_x64.msi"
    destination = "C:/setup/CloudbaseInitSetup_Stable_x64.msi"
  }

  
  provisioner "powershell" {
    elevated_user     = "vagrant"
    elevated_password = "vagrant"
    inline = ["Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-NetIPInterface -InterfaceAlias $_.Name -Dhcp Enabled; Set-DnsClientServerAddress -InterfaceAlias $_.Name -ResetServerAddresses }"
   ]
  }

  provisioner "powershell" {
  inline = [
    "Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 0 2' -ServerAddresses ('192.168.10.1')",
    "Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyServer -Value 'proxy-server:port'",
    "Set-ItemProperty -Path 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -Name ProxyEnable -Value 1"
  ]
}


  provisioner "powershell" {
  inline = [
    "if ((Get-Module -ListAvailable -Name PowerShellGet).Version -lt '2.0.0') { Install-Module -Name PowerShellGet -Force }",
    "if ((Get-PackageProvider -ListAvailable -Name NuGet).Version -lt '2.8.5.201') { Install-PackageProvider -Name NuGet -Force }"
    ]
  }

  provisioner "powershell" {
    inline = [
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force",
      "Install-Module PowerShellGet -Force"
   ]
  }

  provisioner "powershell" {
    elevated_password = "vagrant"
    elevated_user     = "vagrant"
    scripts           = ["/root/gameofAD/packer/proxmox/scripts/sysprep/cloudbase-init.ps1"]
  }

  provisioner "powershell" {
    elevated_password = "vagrant"
    elevated_user     = "vagrant"
    pause_before      = "1m0s"
    scripts           = ["/root/gameofAD/packer/proxmox/scripts/sysprep/cloudbase-init-p2.ps1"]
  }


}

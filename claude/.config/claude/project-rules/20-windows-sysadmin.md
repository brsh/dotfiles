---
trigger: always_on
---

# Windows Sysadmin Context

This file provides context about the Windows environment I work in. Apply this
knowledge when generating scripts, commands, and recommendations.

---

## Environment Context

- **OS**: Windows Server 2016 / 2019 / 2022 / 2025 (mixed environment)
- **Domain**: On-premises Active Directory with Azure AD (Entra ID) hybrid join
- **Management**: Mix of SCCM/MECM, Intune (modern management transition in progress)
- **Identity**: On-prem AD synced to Entra ID via Entra Connect (formerly AAD Connect)
- **Cloud**: Azure (primary cloud), some Microsoft 365 / Exchange Online

---

## Active Directory

### Preferred Cmdlets (RSAT ActiveDirectory module)

```powershell
# Users
Get-ADUser -Identity $SamAccountName -Properties *
Get-ADUser -Filter { Enabled -eq $false -and LastLogonDate -lt $cutoffDate } `
           -SearchBase "OU=Users,DC=contoso,DC=com" `
           -Properties LastLogonDate, PasswordLastSet, Manager

# Groups
Get-ADGroupMember -Identity "Domain Admins" -Recursive
Add-ADGroupMember -Identity "AppAccess-ReadOnly" -Members $SamAccountName

# Computers
Get-ADComputer -Filter { OperatingSystem -like "*Server*" } `
               -Properties OperatingSystem, LastLogonDate, IPv4Address

# Bulk operations — always use -WhatIf first
Get-ADUser -Filter { Enabled -eq $false } | Disable-ADAccount -WhatIf
```

### Key Principles

- **Always use `-Filter` server-side** rather than piping to `Where-Object`.
  Server-side filtering is far more efficient for large directories.
- **Use `-Properties`** only for what you need — retrieving all properties (`*`)
  is expensive; specify the list when possible.
- **`LastLogonDate` vs `LastLogon`**: `LastLogonDate` is replicated across DCs and
  is generally sufficient. `LastLogon` is DC-specific and requires querying all DCs.
- **Tiered admin model**: Assume Tier 0 / Tier 1 / Tier 2 separation. Scripts
  touching Domain Controllers or sensitive OUs should flag required privilege level.
- **LAPS**: If LAPS is deployed, reference `ms-Mcs-AdmPwd` attribute for local admin
  passwords; never set local admin passwords manually on managed machines.

---

## Group Policy

```powershell
# View GPO links on an OU
Get-GPInheritance -Target "OU=Workstations,DC=contoso,DC=com"

# Find all GPOs that set a specific registry value
Get-GPO -All | ForEach-Object {
    Get-GPOReport -Guid $_.Id -ReportType XML | Select-String "SomeRegistryPath"
}

# Force GP update on remote machines
Invoke-GPUpdate -Computer $server -Force -RandomDelayInMinutes 0
```

- Prefer GPO over direct registry edits for domain-wide settings — GPO is auditable,
  reversible, and scoped.
- Document all GPO changes: which GPO, what setting, when, and why.
- Use **WMI filters** and **Security Filtering** instead of per-computer scripting
  where possible.

---

## Registry Operations

```powershell
# Read
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"

# Write (always document why)
Set-ItemProperty -Path "HKLM:\SOFTWARE\..." -Name "ValueName" -Value 1 -Type DWord

# Remote registry (requires RemoteRegistry service running)
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $server)
$key = $reg.OpenSubKey("SOFTWARE\...")
```

Always flag registry modifications. Include the full path and data type in comments.
Prefer GPO for persistent settings — registry changes can be overwritten by GP refresh.

---

## Event Logs

```powershell
# Modern approach — Get-WinEvent (preferred over Get-EventLog)
Get-WinEvent -LogName Security -MaxEvents 100 |
    Where-Object { $_.Id -in @(4624, 4625, 4648) }

# Filter by time and event ID efficiently
$filter = @{
    LogName   = 'System'
    Id        = @(7034, 7036)
    StartTime = (Get-Date).AddHours(-24)
}
Get-WinEvent -FilterHashtable $filter

# Remote event log query
Get-WinEvent -ComputerName $server -FilterHashtable $filter -Credential $cred
```

`Get-WinEvent` with `-FilterHashtable` is far more efficient than piping to
`Where-Object` — filtering happens on the source, not in PowerShell memory.

---

## Services and Scheduled Tasks

```powershell
# Services — use CIM
Get-CimInstance -ClassName Win32_Service -Filter "State='Running'"
Set-Service -Name "Spooler" -StartupType Disabled

# Scheduled Tasks
Get-ScheduledTask -TaskPath "\MyOrg\"
Register-ScheduledTask -TaskName "DiskCleanup" -Action $action -Trigger $trigger `
                       -Principal $principal -RunLevel Highest

# Run as SYSTEM or service account — never run elevated tasks as a domain user
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" `
                                         -LogonType ServiceAccount `
                                         -RunLevel Highest
```

---

## Windows Firewall

```powershell
# Preferred — named NetSecurity module cmdlets
New-NetFirewallRule -DisplayName "Allow HTTPS Inbound" `
                    -Direction Inbound -Protocol TCP -LocalPort 443 `
                    -Action Allow -Profile Domain

Get-NetFirewallRule | Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' }

# Check open ports
Get-NetTCPConnection -State Listen | Sort-Object LocalPort
```

---

## PowerShell Remoting

```powershell
# Preferred for repeated operations — reuse session
$s = New-PSSession -ComputerName $server -Credential $cred
Invoke-Command -Session $s -ScriptBlock { ... }
Remove-PSSession $s

# WinRM quick check
Test-WSMan -ComputerName $server

# JEA endpoint (if configured)
Enter-PSSession -ComputerName $server -ConfigurationName "JEA-DiskAdmin"
```

When writing remoting scripts for teams:
- Document required WinRM configuration
- Document required firewall rules (TCP 5985 HTTP, 5986 HTTPS)
- Prefer HTTPS (5986) with a valid certificate for any cross-segment remoting
- JEA endpoints are preferred over giving users broad admin access

---

## Azure / Entra ID / M365

```powershell
# Az module (preferred over AzureRM)
Connect-AzAccount
Get-AzResourceGroup
Get-AzVM -ResourceGroupName "Production-RG" | Select-Object Name, PowerState

# Microsoft Graph (preferred over MSOL/AzureAD modules — those are deprecated)
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"
Get-MgUser -Filter "accountEnabled eq false"
Get-MgGroupMember -GroupId $groupId

# Exchange Online
Connect-ExchangeOnline -UserPrincipalName admin@contoso.com
Get-Mailbox -ResultSize Unlimited | Where-Object { $_.HiddenFromAddressListsEnabled }
```

**Module deprecation note**: The `MSOnline` and `AzureAD` PowerShell modules are
deprecated. Use **Microsoft Graph PowerShell** (`Microsoft.Graph.*`) for new scripts.
The `ExchangeOnlineManagement` module for Exchange Online work is current.

---

## Security Notes for Windows Scripts

- **Privileged operations**: Note required membership (e.g., "Requires Domain Admin",
  "Requires local Administrator on target machine")
- **Audit logging**: Security-sensitive changes should write to the Windows event log:
  ```powershell
  Write-EventLog -LogName Application -Source "MyScript" -EventId 1000 `
                 -EntryType Information -Message "Changed setting X on $server"
  ```
- **NTFS permissions**: Use `Set-Acl` / `Get-Acl` for scripted permission changes.
  Document the ACL change thoroughly — permission changes are hard to audit retroactively.
- **Execution Policy**: Scripts for deployment should be signed or deployed via a
  mechanism that sets execution policy appropriately. Do not use
  `Set-ExecutionPolicy Unrestricted` in production.
- **Secrets**: Azure Key Vault, Windows Credential Manager, or DPAPI-encrypted
  SecureStrings — never plain-text passwords in scripts or scheduled task arguments.

---

## Windows Server 2025 — Notable Changes

When targeting or managing Windows Server 2025 systems, be aware of these changes
that differ from 2019/2022 and may affect scripts and configurations:

### SMB Signing Enabled by Default

Server 2025 enables SMB signing on **all connections** by default (including client
side). This is a security improvement but can break older scripts and services that
use UNC paths to non-signing hosts:

```powershell
# Check SMB signing status
Get-SmbServerConfiguration | Select-Object RequireSecuritySignature, EnableSecuritySignature
Get-SmbClientConfiguration | Select-Object RequireSecuritySignature

# If you must disable for a specific share (document the security exception)
Set-SmbServerConfiguration -RequireSecuritySignature $false -WhatIf
```

### SMB over QUIC (file shares without VPN)

Server 2025 supports SMB over QUIC — encrypted file share access over the internet
using TLS 1.3, without a traditional VPN. Requires a valid certificate and Azure
Edge or Datacenter licensing:

```powershell
# Enable SMB over QUIC (requires appropriate licensing)
New-SmbServerCertificateMapping -Name "FileShare" -Thumbprint $cert.Thumbprint `
    -StoreName My -Subject "fileserver.contoso.com"
```

### Windows LAPS (Built-in, replaces legacy LAPS)

Server 2025 (and updated 2019/2022) includes **Windows LAPS** natively. The old
legacy LAPS (`ms-Mcs-AdmPwd` attribute) is distinct from Windows LAPS (`msLAPS-Password`):

```powershell
# Windows LAPS (new — built-in, use for new deployments)
Get-LapsADPassword -Identity $ComputerName -AsPlainText
Reset-LapsPassword -Identity $ComputerName

# Check LAPS policy
Get-LapsADPasswordExpirationTime -Identity $ComputerName

# Legacy LAPS (old — still in use if not migrated)
(Get-ADComputer $ComputerName -Properties 'ms-Mcs-AdmPwd').'ms-Mcs-AdmPwd'
```

When writing scripts that retrieve local admin passwords, confirm which LAPS
generation is deployed. Windows LAPS requires `Update-LapsADSchema` to have been run.

### Delegated Managed Service Accounts (dMSA)

Server 2025 introduces dMSA — an evolution of gMSA that works without requiring
the `PrincipalsAllowedToRetrieveManagedPassword` group:

```powershell
# Create a dMSA (requires AD 2025 functional level)
New-ADServiceAccount -Name "svc-myapp" -DNSHostName "svc-myapp.contoso.com" `
    -CreateDelegatedServiceAccount

# Still prefer gMSA for mixed-level environments
New-ADServiceAccount -Name "svc-myapp" -DNSHostName "svc-myapp.contoso.com" `
    -PrincipalsAllowedToRetrieveManagedPassword "MyAppServers"
```

### Hotpatching

Server 2025 Datacenter Azure Edition supports hotpatching (applying security updates
without a reboot) when Azure Arc-connected. Standard hotpatch cycles apply only to
baseline months; feature updates still require reboots:

```powershell
# Check hotpatch status (requires Azure Arc agent)
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10

# Check Arc connection status
azcmagent show
```

### Hyper-V and Storage Updates

- **Virtual Machine GPU partitioning** (GPU-P) is supported for remote workloads
- **NVMe storage** performance improvements for VMs
- **Storage Spaces Direct** enhancements for S2D clusters
- **ReFS** now supports deduplication natively

### Active Directory — Server 2025 Functional Level

New features available when domain/forest functional level is raised to 2025:
- dMSA support
- Improved Kerberos authentication (AES-only enforcement)
- `msDS-preferredPasswordLength` per-user password length enforcement

```powershell
# Check current functional level
(Get-ADDomain).DomainMode
(Get-ADForest).ForestMode

# Raise functional level (irreversible — test in staging first)
Set-ADDomainMode -Identity "contoso.com" -DomainMode Windows2025Domain -WhatIf
```

### PowerShell Remoting over SSH (Server 2025 ships with OpenSSH)

Server 2025 ships OpenSSH as a Windows Capability. Use SSH-based PS remoting as a
cross-platform alternative to WinRM:

```powershell
# SSH-based remoting (PS 7+ on both sides)
Enter-PSSession -HostName server.contoso.com -UserName admin -SSHTransport
New-PSSession -HostName @('srv1', 'srv2') -UserName admin -SSHTransport
```

---

## Common Tools and Their PowerShell Equivalents

| Task | Preferred Approach |
|------|--------------------|
| DNS lookup | `Resolve-DnsName` |
| Test connectivity | `Test-NetConnection -ComputerName x -Port 443` |
| Check open ports | `Get-NetTCPConnection` |
| Remote file copy | `Copy-Item -Path ... -Destination ... -ToSession $s` |
| AD user report | `Get-ADUser` + `Export-Csv` |
| Event log search | `Get-WinEvent -FilterHashtable` |
| Service management | `Get-Service`, `Set-Service`, `CIM Win32_Service` |
| Process management | `Get-Process`, `Stop-Process`, `CIM Win32_Process` |
| Disk/volume info | `Get-Volume`, `Get-PSDrive` |
| Installed software | `Get-Package` or `CIM Win32_Product` (slow) |

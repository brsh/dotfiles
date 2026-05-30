---
trigger: glob
glob: "**/*.{ps1,psm1,psd1,ps1xml}"
description: "PowerShell scripting best practices for sysadmin automation"
---

# PowerShell Rules

## Script Structure

Every non-trivial script should follow this structure:

```powershell
#Requires -Version 5.1
#Requires -Modules ActiveDirectory   # declare dependencies

<#
.SYNOPSIS
    One-line summary of what this script does.
.DESCRIPTION
    Longer explanation. What problem it solves, what it touches, what it requires.
.PARAMETER TargetOU
    Description of the parameter.
.EXAMPLE
    .\Invoke-UserCleanup.ps1 -TargetOU "OU=Disabled,DC=contoso,DC=com" -WhatIf
.NOTES
    Author: Name
    Requires: ActiveDirectory module, Domain Read permissions
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetOU,

    [Parameter()]
    [ValidateSet('Enabled', 'Disabled', 'All')]
    [string]$AccountStatus = 'All'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

---

## Naming Conventions

- **Functions**: `Verb-Noun` format using approved verbs. Run `Get-Verb` for the full list.
  - Good: `Get-StaleAdAccount`, `Set-ServiceCredential`, `Invoke-DiskCleanup`
  - Bad: `CleanDisk`, `doUserStuff`, `Process-User`
- **Parameters**: `$PascalCase`
- **Internal variables**: `$camelCase`
- **Constants**: `$ALL_CAPS` or `$PascalCase` with `Set-Variable -Option ReadOnly`
- **No aliases in scripts**: Use `Get-ChildItem`, not `ls` or `gci`. Use `Write-Output`,
  not `echo`. Aliases are for interactive use only.

---

## Parameter Validation (use these liberally)

```powershell
[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[string]$Name

[ValidateSet('Read', 'Write', 'ReadWrite')]
[string]$AccessLevel

[ValidateRange(1, 365)]
[int]$DaysOld

[ValidatePattern('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')]
[string]$Email

[ValidateScript({ Test-Path $_ -PathType Leaf })]
[string]$FilePath
```

---

## Error Handling

Use structured try/catch with specific exception types where possible:

```powershell
try {
    $user = Get-ADUser -Identity $SamAccountName -ErrorAction Stop
} catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Warning "User '$SamAccountName' not found in Active Directory."
    return
} catch [System.UnauthorizedAccessException] {
    Write-Error "Insufficient permissions to query AD. Verify your account has read access."
    throw
} catch {
    Write-Error "Unexpected error querying AD: $_"
    throw
} finally {
    # cleanup (close connections, remove temp files, etc.)
}
```

- Use `-ErrorAction Stop` to convert non-terminating errors into terminating ones that
  can be caught.
- Use `$ErrorActionPreference = 'Stop'` at the top to apply globally, then selectively
  use `-ErrorAction SilentlyContinue` where you explicitly want to ignore errors.
- Always log or surface errors — never swallow them silently.

---

## WhatIf / Dry Run (required for destructive operations)

Any script that modifies, deletes, or moves data must support `-WhatIf`:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(...)

# For built-in cmdlets:
Remove-ADUser -Identity $user -WhatIf:$WhatIfPreference

# For custom logic:
if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable AD account')) {
    Disable-ADAccount -Identity $user
}
```

Run with `-WhatIf` to preview all actions without executing them. This is not optional
for scripts that touch AD, Exchange, file systems, or system configuration.

---

## Modern PowerShell Preferences

**Use CIM, not WMI** (WMI is deprecated in PowerShell 6+):

```powershell
# Preferred
Get-CimInstance -ClassName Win32_OperatingSystem
Get-CimInstance -ClassName Win32_Service -Filter "Name='Spooler'"

# Avoid
Get-WmiObject -Class Win32_OperatingSystem   # deprecated
```

**Use pipeline-friendly output** — return objects, not formatted strings:

```powershell
# Good — returns a usable object
[PSCustomObject]@{
    ComputerName = $computer
    DiskFreeGB   = [math]::Round($disk.FreeSpace / 1GB, 2)
    Status       = 'OK'
}

# Avoid — hard to process downstream
Write-Output "$computer has $([math]::Round($disk.FreeSpace / 1GB, 2)) GB free"
```

**Build collections efficiently** — don't use `+=` on arrays:

```powershell
# Preferred — much faster for large sets
$results = [System.Collections.Generic.List[PSObject]]::new()
$results.Add($item)

# Avoid — creates a new array on every iteration
$results = @()
$results += $item
```

---

## Cross-Platform Compatibility (5.1 vs 7+)

PowerShell exists in two distinct lineages that share most syntax but differ
meaningfully in runtime, available features, and platform support:

| | Windows PowerShell 5.1 | PowerShell 7+ |
|-|------------------------|---------------|
| Runtime | .NET Framework 4.x | .NET 8+ |
| Platforms | Windows only | Windows, Linux, macOS |
| Support status | Maintenance only (no new features) | Active development |
| WMI cmdlets | Available | Removed (use CIM) |
| Windows modules | Full support | Windows-only modules still Windows-only |
| Default encoding | UTF-16LE (Out-File) | UTF-8 no BOM |
| Remoting | WinRM only | WinRM (Windows) + SSH (all platforms) |

---

### Detecting Version and Platform

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion   # Major.Minor.Patch
$PSVersionTable.PSEdition   # 'Desktop' = 5.1, 'Core' = 7+

# Platform detection (PS 7+ ONLY — these variables don't exist in 5.1)
if ($IsWindows) { ... }
if ($IsLinux)   { ... }
if ($IsMacOS)   { ... }

# Safe cross-version platform check (works in both 5.1 and 7+)
$onWindows = $env:OS -eq 'Windows_NT'   # works everywhere
# or:
$onWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::Windows
)
```

**Important**: `$IsWindows`, `$IsLinux`, `$IsMacOS` **do not exist in Windows
PowerShell 5.1**. Using them without a guard causes a `$null` comparison, not an
error — which can cause silent logic bugs. Always use the safe cross-version check
in scripts that must run on both.

---

### PS 7+ Only Features (will break in 5.1)

```powershell
# Ternary operator (PS 7+)
$result = $condition ? "yes" : "no"

# Null coalescing (PS 7+)
$value = $possiblyNull ?? "default"
$value ??= "default"    # null coalescing assignment

# Pipeline chain operators (PS 7+)
Start-Service nginx && Write-Output "Started" || Write-Error "Failed"

# Parallel ForEach (PS 7+)
$servers | ForEach-Object -Parallel {
    Test-Connection $_ -Count 1 -Quiet
} -ThrottleLimit 10

# Get-Error (PS 7+) — much more detailed error info than $Error[0]
Get-Error

# $ErrorView = 'ConciseView' (PS 7+ default) — cleaner error output
# $ErrorView = 'DetailedView' — full error with stack trace
```

If a script **must run on 5.1**, avoid all of the above. Use `#Requires -Version 7`
at the top to explicitly declare the requirement if 7+ features are used.

---

### Encoding (a common source of cross-platform bugs)

```powershell
# PS 5.1 defaults — Out-File and Set-Content write UTF-16LE (with BOM)
# PS 7+ defaults — UTF-8 no BOM for everything

# Always specify encoding explicitly in scripts for portability
Out-File -FilePath output.txt -Encoding UTF8       # works in both
Set-Content -Path output.txt -Value $data -Encoding UTF8
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)

# Reading files — also be explicit
Get-Content -Path file.txt -Encoding UTF8
[System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Check what encoding a file actually is
$bytes = [System.IO.File]::ReadAllBytes($path)
# UTF-16LE BOM: EF BB BF; UTF-8 BOM: FF FE; no BOM needs context
```

---

### Path Handling (cross-platform critical)

```powershell
# Never hardcode path separators
# Bad
$path = "C:\Scripts\output"
$path = "/home/user/scripts"

# Good — always use Join-Path
$path = Join-Path $PSScriptRoot "output"
$logFile = Join-Path $env:TEMP "myscript.log"

# Cross-platform temp path
$tempDir = [System.IO.Path]::GetTempPath()

# Path separator character if you need it
$sep = [System.IO.Path]::DirectorySeparatorChar

# Test paths work identically across platforms
Test-Path $path
Split-Path $path -Leaf      # filename
Split-Path $path -Parent    # directory
```

---

### Windows-Only Modules and Cmdlets

These work in PS 7+ **only on Windows**. They will fail on Linux/macOS:

```powershell
# Windows-only even in PS 7
Import-Module ActiveDirectory   # only on Windows with RSAT
Import-Module GroupPolicy
Import-Module Hyper-V
Get-Service                     # works on Linux/macOS but limited
Set-Service                     # Windows only
Get-WinEvent                    # Windows only
New-NetFirewallRule             # Windows only
Get-ScheduledTask               # Windows only
```

If writing a cross-platform script that has Windows-specific sections:

```powershell
if ($IsWindows -or $env:OS -eq 'Windows_NT') {
    # Windows-only operations
    Get-WinEvent -LogName Security -MaxEvents 10
} else {
    # Linux/macOS equivalent
    Get-Content /var/log/auth.log -Tail 10
}
```

---

### Remoting: WinRM vs SSH

```powershell
# WinRM remoting — Windows to Windows (5.1 and 7+)
New-PSSession -ComputerName $server -Credential $cred

# SSH remoting — cross-platform (PS 7+ on both sides, OpenSSH required)
New-PSSession -HostName $server -UserName $user -SSHTransport
Enter-PSSession -HostName $linuxServer -UserName admin -SSHTransport

# SSH remoting to Windows Server 2025 (OpenSSH now ships with Server 2025)
Enter-PSSession -HostName winserver25 -UserName admin -SSHTransport
```

Use SSH-based remoting when:
- Target is Linux or macOS
- You want to avoid WinRM configuration complexity
- Both sides run PS 7+

---

### Script Header Guidance

```powershell
# 5.1-compatible (default — be explicit about which modules you need)
#Requires -Version 5.1
#Requires -Modules ActiveDirectory

# PS 7+ required (use 7+ features freely)
#Requires -Version 7.0

# PS 7+ with specific module
#Requires -Version 7.2
#Requires -Modules @{ ModuleName = 'Az'; ModuleVersion = '11.0.0' }
```

Use `#Requires -Version 7.0` whenever you use PS 7+ syntax. This gives a clear
error at startup instead of a confusing runtime failure.

---

## Credentials and Secrets

```powershell
# Interactive (for scripts that run with user present)
$cred = Get-Credential -Message "Enter service account credentials"

# Non-interactive with Windows Credential Manager (CredentialManager module)
$cred = Get-StoredCredential -Target "MyApp-ServiceAccount"

# Azure Key Vault (preferred for automated scripts)
$secret = Get-AzKeyVaultSecret -VaultName "MyVault" -Name "ServicePassword" -AsPlainText

# SecureString from environment (CI/CD pipelines)
$securePass = ConvertTo-SecureString $env:SERVICE_PASSWORD -AsPlainText -Force
$cred = [PSCredential]::new($env:SERVICE_USERNAME, $securePass)
```

Never use `ConvertTo-SecureString "PlaintextPassword" -AsPlainText -Force` with a
literal password in a script. The plaintext is visible to anyone who reads the file.

---

## Logging

```powershell
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] [$Level] $Message"
    Write-Verbose $logLine
    if ($LogPath) { Add-Content -Path $LogPath -Value $logLine }
    if ($Level -eq 'ERROR') { Write-Error $Message }
    elseif ($Level -eq 'WARN') { Write-Warning $Message }
}
```

Use `Start-Transcript` for full session logging. Use `Write-Verbose` for operational
detail (shown with `-Verbose`). Use `Write-Debug` for developer-level tracing.

---

## Remoting Best Practices

```powershell
# Preferred — single connection, multiple commands
$session = New-PSSession -ComputerName $server -Credential $cred
try {
    Invoke-Command -Session $session -ScriptBlock { Get-Service }
    Invoke-Command -Session $session -ScriptBlock { Get-EventLog -LogName System -Newest 10 }
} finally {
    Remove-PSSession $session
}

# For one-off commands
Invoke-Command -ComputerName $server -ScriptBlock { ... } -Credential $cred
```

Use `$using:variableName` to pass local variables into remote script blocks.

---

## Testing with Pester

Every reusable function or module should have Pester tests:

```powershell
Describe "Get-StaleAdAccount" {
    BeforeAll {
        # Mock AD calls to avoid needing a real AD environment
        Mock Get-ADUser { return @{ SamAccountName = "testuser"; Enabled = $false } }
    }

    It "returns disabled accounts older than 90 days" {
        $result = Get-StaleAdAccount -DaysInactive 90
        $result | Should -Not -BeNullOrEmpty
    }

    It "throws when DaysInactive is less than 1" {
        { Get-StaleAdAccount -DaysInactive 0 } | Should -Throw
    }
}
```

Run tests with: `Invoke-Pester -Path .\tests\ -Output Detailed`

---

## Module Structure

For reusable modules:

```
MyModule\
├── MyModule.psd1          # manifest (version, dependencies, exported functions)
├── MyModule.psm1          # module root (imports all function files)
├── Public\                # exported functions (one file per function)
│   ├── Get-Thing.ps1
│   └── Set-Thing.ps1
├── Private\               # internal helpers (not exported)
│   └── ConvertTo-Formatted.ps1
└── tests\
    └── Get-Thing.Tests.ps1
```

---

## Common Pitfalls to Flag

When you see these patterns, point them out:

- `Get-WmiObject` → suggest `Get-CimInstance`
- `$array += $item` in a loop → suggest `List[T]`
- `Out-File` or `Set-Content` without `-Encoding UTF8` → can cause encoding issues
- `Invoke-Expression` with any dynamic content → serious injection risk
- Don't use `Write-Host` as a substitute for pipeline output — but it's appropriate
  for terminal UI/display-only color output. Prefer `Write-Status` (for modules where it exists in `private/Write-Status.ps1`)
  for all status/progress output in this module:
  - `-Message` / `-Type` are parallel arrays (one type per message)
  - `-Type` prefixes: `Good` (green), `Error` (red), `Warning` (yellow), `Debug` (cyan),
    default (theme info color); append `High` for highlighted background (e.g. `'GoodHigh'`)
  - Special types: `Skip` suppresses that one message and continues; `Stop` aborts all remaining output
  - `-Level` for indentation depth; `-LogPath` to also append to a file; `-e` for ErrorRecord display
- Missing `-ErrorAction Stop` on cmdlets inside try/catch → won't catch errors
- `[System.Net.ServicePointManager]::SecurityProtocol` hardcoded → use `-UseBasicParsing`
  or set TLS version dynamically
- Passwords in `ConvertTo-SecureString` as string literals → always flag this
- `[math]::Round($intValue, 2)` in Windows PowerShell 5.1 → silently picks the wrong
  overload; always cast the first argument: `[math]::Round([double]$value, 2)`
- Local variable name matching a parameter name (case-insensitively) → PS is
  case-insensitive, so `$sorted` silently shadows a `-Sorted` switch parameter at
  runtime with no error; rename the local variable to avoid the collision
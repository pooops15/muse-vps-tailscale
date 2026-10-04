# windows-setup.ps1 — prepare YOUR Windows laptop for the Tailscale
# reverse SSH setup. Run this ON THE LAPTOP, in PowerShell as
# Administrator (right-click PowerShell -> Run as administrator).
#
# What it does, in order:
#   1. Checks that it really runs as Administrator.
#   2. Checks the Windows OpenSSH Server service (sshd) — tells you if it
#      is missing or not running yet.
#   3. Asks you to paste the Muse VM's PUBLIC key (one line starting
#      with "ssh-ed25519"). A public key is made to be shared; the
#      private half never leaves the VM.
#   4. Opens the Windows Firewall for SSH coming from the Tailscale
#      network range only (100.64.0.0/10) — not from the whole internet.
#   5. Saves the VM's public key into
#      C:\ProgramData\ssh\administrators_authorized_keys
#      (skips it if the key is already there) and locks that file's
#      permissions to Administrators + SYSTEM, which Windows sshd
#      demands.
#   6. Prints the remaining manual check: in the Tailscale tray icon,
#      Preferences must have "Allow incoming connections" enabled
#      (that is the off-switch for "Shields Up").
#
# NOTE: if your Windows account is NOT in the Administrators group,
# Windows sshd reads %USERPROFILE%\.ssh\authorized_keys instead of the
# ProgramData file above. The tutorial (docs/TUTORIAL.md) explains both.

$ErrorActionPreference = 'Stop'

# --- 1. Am I Administrator? -------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: this window is not Administrator." -ForegroundColor Red
    Write-Host "Close it, right-click PowerShell, choose 'Run as administrator', then run this script again."
    exit 1
}
Write-Host "[1/5] Administrator: OK"

# --- 2. Is the OpenSSH server present and running? --------------------------
$svc = Get-Service sshd -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Host "[2/5] OpenSSH Server (sshd) is NOT installed yet." -ForegroundColor Yellow
    Write-Host "Install it with these two commands, then run this script again:"
    Write-Host "  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
    Write-Host "  Start-Service sshd; Set-Service sshd -StartupType Automatic"
    exit 1
}
if ($svc.Status -ne 'Running') {
    Write-Host "[2/5] sshd exists but is not running — starting it now..."
    Start-Service sshd
    Set-Service sshd -StartupType Automatic
}
Write-Host "[2/5] OpenSSH Server (sshd): Running"

# --- 3. Ask for the VM's public key ----------------------------------------
Write-Host ""
Write-Host "[3/5] Paste the Muse VM's PUBLIC key (one line, starts with ssh-ed25519),"
$vmKey = Read-Host "then press Enter"
$vmKey = $vmKey.Trim()
if ($vmKey -notmatch '^ssh-(ed25519|rsa|ecdsa)\s+AAAA') {
    Write-Host "ERROR: that does not look like a public key line." -ForegroundColor Red
    Write-Host "It must start with 'ssh-ed25519 AAAA...'. Nothing was changed."
    exit 1
}

# --- 4. Firewall rule for the Tailscale range only --------------------------
$ruleName = 'SSH Tailscale'
if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
    Write-Host "[4/5] Firewall rule '$ruleName' already exists: OK"
} else {
    netsh advfirewall firewall add rule name="SSH Tailscale" dir=in action=allow protocol=TCP localport=22 remoteip=100.64.0.0/10 | Out-Host
    Write-Host "[4/5] Firewall rule '$ruleName' added (TCP 22, from 100.64.0.0/10 only)"
}

# --- 5. Save the key + lock the file permissions ----------------------------
$authFile = 'C:\ProgramData\ssh\administrators_authorized_keys'
$existing = ''
if (Test-Path $authFile) { $existing = Get-Content $authFile -Raw }
if ($existing -like "*$($vmKey.Split(' ')[1])*") {
    Write-Host "[5/5] The VM key is already in administrators_authorized_keys: OK"
} else {
    Add-Content -Path $authFile -Value $vmKey -Encoding ascii
    Write-Host "[5/5] VM key saved to administrators_authorized_keys"
}
icacls $authFile /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Host

# --- 6. Last manual check ----------------------------------------------------
Write-Host ""
Write-Host "DONE on this laptop. One last manual check:" -ForegroundColor Green
Write-Host "  Right-click the Tailscale icon near the clock -> Preferences"
Write-Host "  -> 'Allow incoming connections' must be ON (that means Shields Up is off)."
Write-Host ""
Write-Host "After that, tell Muse (in your chat) that the laptop is ready."
Write-Host "Muse will test the road, start the reverse tunnel, and give you"
Write-Host "the final connect command."

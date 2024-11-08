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
# Color Variables
# ---------------------------
$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[0;33m"
$CYAN = "`e[0;36m"
$NC = "`e[0m" # No Color

# ---------------------------
# Function to Print Colored Text
# ---------------------------
function Print-Colored {
    param (
        [string]$Message,
        [string]$Color
    )
    Write-Host "$Color$Message$NC"
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
# Display Banner
# ---------------------------
Print-Colored @"

██ ██████     ████ ██████   ██████ ██████   ██ ████████   ██████
██ ██    ██ ██     ██    ██ ██     ██    ██ ██ ██  ██  ██ ██    ██
██ ██    ██ ██     ██████   ████   ██    ██ ██ ██  ██  ██ ██    ██
██ ██    ██ ██████ ██    ██ ██████ ██████   ██ ██  ██  ██   ██████
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DESKTOP-07MDBHS | nobody | 08-11-2024 07:48 PM
AMD64 | Windows_NT | PS 7.4.6
BUILD INCREDIBLE THINGS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@ $CYAN

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
    Write-Host "[$timestamp] $($Color): $Message$NC" -ForegroundColor $Color
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
# Inform the User to Reload the Profile or Restart PowerShell
# ---------------------------
Write-Log "Installation completed successfully." -Color "Green"
Write-Log "To apply the new profile, either restart PowerShell or run the following command:" -Color "Yellow"
Write-Host "    . $PROFILE" -ForegroundColor "White"

# Optionally, reload the profile automatically
# Uncomment the line below if you want the script to reload the profile automatically
# . $PROFILE

# ---------------------------
# End of Script
# ---------------------------

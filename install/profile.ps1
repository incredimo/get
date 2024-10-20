<#
.SYNOPSIS
    Installs a custom PowerShell profile from a specified URL.

.DESCRIPTION
    This script downloads a PowerShell profile script from a given URL and installs it
    to the current user's PowerShell profile path. If a profile already exists, it creates
    a timestamped backup before overwriting it. The script includes comprehensive logging
    and error handling to ensure a smooth installation process.

.NOTES
    - URL of the custom profile: https://xo.rs/profile.ps1
    - Ensure you have an active internet connection.
    - Git is not required for installation, but the profile may utilize Git commands.
    - Run this script with appropriate permissions to modify your PowerShell profile.

.EXAMPLE
    .\Install-CustomProfile.ps1
#>

# Function to write log messages with timestamps and colors
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Green", "Yellow", "Red", "Cyan", "White")]
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Variables
$profileUrl = "https://xo.rs/profile.ps1"
$profilePath = $PROFILE
$profileDirectory = Split-Path -Path $profilePath -Parent
$backupDirectory = Join-Path -Path $profileDirectory -ChildPath "Backups"

# Start Installation
Write-Log "Starting installation of the custom PowerShell profile..." -Color "Cyan"

# Ensure the profile directory exists
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

# Backup existing profile if it exists
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

# Download the custom profile
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

# Validate the downloaded file
if (-not (Test-Path -Path $tempProfilePath)) {
    Write-Log "Downloaded profile file not found at '$tempProfilePath'." -Color "Red"
    exit 1
}

# Write the profile to the profile path
try {
    Copy-Item -Path $tempProfilePath -Destination $profilePath -Force
    Write-Log "Custom profile installed to '$profilePath'." -Color "Green"
}
catch {
    Write-Log "Failed to install the custom profile to '$profilePath'. Error: $_" -Color "Red"
    exit 1
}

# Clean up the temporary file
try {
    Remove-Item -Path $tempProfilePath -Force
    Write-Log "Removed temporary profile file at '$tempProfilePath'." -Color "Green"
}
catch {
    Write-Log "Failed to remove temporary profile file at '$tempProfilePath'. Error: $_" -Color "Yellow"
}

# Inform the user to reload the profile or restart PowerShell
Write-Log "Installation completed successfully." -Color "Green"
Write-Log "To apply the new profile, either restart PowerShell or run the following command:" -Color "Yellow"
Write-Host "    . $PROFILE" -ForegroundColor "White"

# Optionally, reload the profile automatically
# Uncomment the line below if you want the script to reload the profile automatically
# . $PROFILE

# End of Script

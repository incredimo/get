# Variables
$RepoUrl = "u-tra/textra" # Replace with your GitHub repository
$AppName = "textra" # Replace with the name of your application

# Color variables
$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[0;33m"
$CYAN = "`e[0;36m"
$NC = "`e[0m" # No Color

# Function to print colored text
function Print-Colored {
    param (
        [string]$Message,
        [string]$Color
    )
    Write-Host "$Color$Message$NC"
}

# Function to check if a command exists
function Command-Exists {
    param (
        [string]$Command
    )
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Function to run a command with or without elevation, based on user privileges
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

# Function to download the latest release from a GitHub repository
function Download-LatestRelease {
    param (
        [string]$Repo
    )

    # Fetch the latest release data from GitHub API
    $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
    $releaseData = Invoke-RestMethod -Uri $apiUrl -Headers @{Accept = "application/vnd.github.v3+json"}

    if (-not $releaseData) {
        Print-Colored "Failed to fetch the latest release data." $RED
        exit 1
    }

    if ($releaseData.assets.Count -eq 0) {
        Print-Colored "No assets found in the latest release." $RED
        exit 1
    }

    $downloadUrl = $releaseData.assets[0].browser_download_url
    $fileName = $releaseData.assets[0].name

    Print-Colored "Downloading the latest release: $fileName..." $CYAN
    Invoke-WebRequest -Uri $downloadUrl -OutFile $fileName
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to download the release." $RED
        exit 1
    }

    return $fileName
}

# Function to run the downloaded file
function Run-DownloadedFile {
    param (
        [string]$FileName
    )

    Print-Colored "Running the downloaded file: $FileName..." $CYAN
    Start-Process -FilePath $FileName -Wait
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to run the downloaded file." $RED
        exit 1
    }
}

# Display banner
Print-Colored "
 |██   |██  |██████      |██████   |███████
|  ██ |██/ |██__  ██    |██__  ██ |██_____/
 \  ████/ | ██  \ ██   | ██  \__/|  ██████ 
  >██  ██ | ██  | ██   | ██       \____  ██
 |██/\  ██|  ██████|██|| ██       |███████/
|__/  \__/ \______/|__/|__/      |_______/ 
---------------------------------------------
 github.com/incredimo | aghil@xo.rs | xo.rs
---------------------------------------------
INSTALLING $AppName ON WINDOWS
---------------------------------------------
" $CYAN

# Start the process
Print-Colored "Fetching the latest release from $RepoUrl..." $CYAN
$fileName = Download-LatestRelease -Repo $RepoUrl
Run-DownloadedFile -FileName $fileName
Print-Colored "$AppName installation completed successfully." $GREEN

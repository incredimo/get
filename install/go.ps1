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

# Display banner
Print-Colored "
 /██   /██  /██████      /██████   /███████
|  ██ /██/ /██__  ██    /██__  ██ /██_____/
 \  ████/ | ██  \ ██   | ██  \__/|  ██████ 
  >██  ██ | ██  | ██   | ██       \____  ██
 /██/\  ██|  ██████//██| ██       /███████/
|__/  \__/ \______/|__/|__/      |_______/ 
---------------------------------------------
 github.com/incredimo | aghil@xo.rs | xo.rs
---------------------------------------------
INSTALLING GO ON WINDOWS
---------------------------------------------
" $CYAN

# Check if wget is installed, if not install it
Print-Colored "Checking if wget is installed..." $CYAN
if (-not (Command-Exists "wget")) {
    Print-Colored "wget not found. Please install wget manually." $RED
    exit 1
} else {
    Print-Colored "wget is already installed." $GREEN
}

# Check if tar is installed, if not install it
Print-Colored "Checking if tar is installed..." $CYAN
if (-not (Command-Exists "tar")) {
    Print-Colored "tar not found. Please install tar manually." $RED
    exit 1
} else {
    Print-Colored "tar is already installed." $GREEN
}

# Get the latest Go version
Print-Colored "Checking the latest Go version..." $CYAN
$goVersion = wget -UseBasicParsing -Uri https://go.dev/VERSION?m=text
if ($goVersion -eq $null) {
    Print-Colored "Failed to fetch the latest Go version." $RED
    exit 1
}

$goVersion = $goVersion.Content.Trim()
$goZip = "go$goVersion.windows-amd64.zip"

# Check if Go is installed and get the installed version
if (Command-Exists "go") {
    $installedVersion = (go version).Split(" ")[2].TrimStart("go")
    Print-Colored "Installed Go version: $installedVersion" $CYAN
} else {
    $installedVersion = ""
}

# Compare versions and decide whether to update or not
if ($installedVersion -ne $goVersion) {
    Print-Colored "Updating Go to the latest version $goVersion..." $CYAN

    # Download the latest Go tarball
    Print-Colored "Downloading Go $goVersion tarball..." $CYAN
    wget "https://go.dev/dl/$goZip" -OutFile $goZip
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to download Go tarball." $RED
        exit 1
    }

    # Remove any previous Go installation
    Print-Colored "Removing any previous Go installation..." $CYAN
    Remove-Item -Recurse -Force "C:\Go" -ErrorAction SilentlyContinue

    # Extract Go tarball to C:\Go
    Print-Colored "Extracting Go tarball to C:\Go..." $CYAN
    Expand-Archive -Path $goZip -DestinationPath C:\Go
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to extract Go tarball." $RED
        exit 1
    }

    # Cleanup downloaded tarball
    Print-Colored "Cleaning up downloaded tarball..." $CYAN
    Remove-Item -Force $goZip

    # Add Go to PATH
    Print-Colored "Adding Go to PATH..." $CYAN
    $env:Path += ";C:\Go\bin"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)

    # Verify Go installation
    Print-Colored "Verifying Go installation..." $CYAN
    if (Command-Exists "go") {
        Print-Colored "Go $goVersion has been successfully installed." $GREEN
        go version
    } else {
        Print-Colored "Go installation verification failed." $RED
        exit 1
    }
} else {
    Print-Colored "Go is already up-to-date." $GREEN
}

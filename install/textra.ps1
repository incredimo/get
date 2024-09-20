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

# Check if winget is available
Print-Colored "Checking if winget is installed..." $CYAN
if (Command-Exists "winget") {
    Print-Colored "winget is available. Installing Go using winget..." $CYAN
    Run-Command winget install -e --id golang.Go
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to install Go using winget." $RED
        exit 1
    }

    # Verify Go installation
    Print-Colored "Verifying Go installation..." $CYAN
    if (Command-Exists "go") {
        Print-Colored "Go has been successfully installed using winget." $GREEN
        go version
    } else {
        Print-Colored "Go installation verification failed." $RED
        exit 1
    }
} else {
    Print-Colored "winget is not available. Falling back to wget and msiexec..." $YELLOW

    # Check if wget is installed, if not install it
    Print-Colored "Checking if wget is installed..." $CYAN
    if (-not (Command-Exists "wget")) {
        Print-Colored "wget not found. Please install wget manually." $RED
        exit 1
    } else {
        Print-Colored "wget is already installed." $GREEN
    }

    # Get the latest Go version
    Print-Colored "Checking the latest Go version..." $CYAN
    $goVersion = (Invoke-WebRequest -Uri "https://go.dev/VERSION?m=text").Content.Trim()
    if ($goVersion -eq $null) {
        Print-Colored "Failed to fetch the latest Go version." $RED
        exit 1
    }

    $goMsi = "go$goVersion.windows-amd64.msi"

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

        # Download the latest Go installer
        Print-Colored "Downloading Go $goVersion installer..." $CYAN
        Invoke-WebRequest -Uri "https://go.dev/dl/$goMsi" -OutFile $goMsi
        if ($LASTEXITCODE -ne 0) {
            Print-Colored "Failed to download Go installer." $RED
            exit 1
        }

        # Run the installer
        Print-Colored "Running Go installer..." $CYAN
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $goMsi /quiet /norestart" -Wait
        if ($LASTEXITCODE -ne 0) {
            Print-Colored "Failed to install Go." $RED
            exit 1
        }

        # Cleanup downloaded installer
        Print-Colored "Cleaning up downloaded installer..." $CYAN
        Remove-Item -Force $goMsi

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
}

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
INSTALLING REQUIRED TOOLS ON WINDOWS
---------------------------------------------
" $CYAN

# Ensure winget is installed
Print-Colored "Checking if winget is installed..." $CYAN
if (-not (Command-Exists "winget")) {
    Print-Colored "winget is not available. Please install winget manually from https://github.com/microsoft/winget-cli" $RED
    exit 1
} else {
    Print-Colored "winget is available." $GREEN
}

# Install CMake
Print-Colored "Checking if CMake is installed..." $CYAN
if (-not (Command-Exists "cmake")) {
    Print-Colored "Installing CMake using winget..." $CYAN
    Run-Command winget install -e --id Kitware.CMake
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to install CMake using winget." $RED
        exit 1
    }
    Print-Colored "CMake has been successfully installed." $GREEN
} else {
    Print-Colored "CMake is already installed." $GREEN
    cmake --version
}
# Function to refresh the environment variables
function Refresh-EnvironmentVariables {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Check if Ninja is installed and add to PATH if necessary
Print-Colored "Checking if Ninja is installed..." $CYAN
$installed = $false
if (Command-Exists "ninja") {
    Print-Colored "Ninja is already installed." $GREEN
    $installed = $true
} else {
    Print-Colored "Installing Ninja using winget..." $CYAN
    Run-Command winget install -e --id NinjaBuild.Ninja
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to install Ninja using winget." $RED
        exit 1
    }
    Refresh-EnvironmentVariables
    if (Command-Exists "ninja") {
        Print-Colored "Ninja has been successfully installed." $GREEN
        $installed = $true
    } else {
        Print-Colored "Ninja installation verification failed." $RED
        exit 1
    }
}

# Set up PATH environment variable if Ninja was installed
if ($installed) {
    $ninjaPath = (Get-Command ninja).Path
    $ninjaDir = [System.IO.Path]::GetDirectoryName($ninjaPath)
    if ($envPath -notcontains $ninjaDir) {
        Print-Colored "Adding Ninja to PATH..." $CYAN
        [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$ninjaDir", "User")
    }
}
 

# Install Visual Studio Build Tools
Print-Colored "Checking for Visual Studio Build Tools..." $CYAN
$vsBuildToolsPath = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe"
if (-not (Test-Path $vsBuildToolsPath)) {
    Print-Colored "Visual Studio Build Tools not found. Installing using winget..." $CYAN
    Run-Command winget install -e --id Microsoft.VisualStudio.2019.BuildTools
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to install Visual Studio Build Tools." $RED
        exit 1
    }
    Print-Colored "Visual Studio Build Tools have been successfully installed." $GREEN
} else {
    Print-Colored "Visual Studio Build Tools are already installed." $GREEN
}

# Set environment variables (if necessary)
Print-Colored "Setting up environment variables..." $CYAN

# Adding CMake and Ninja to PATH if they are not there
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$cmakePath = (Get-Command cmake).Path
$ninjaPath = (Get-Command ninja).Path

if ($envPath -notcontains [System.IO.Path]::GetDirectoryName($cmakePath)) {
    Print-Colored "Adding CMake to PATH..." $CYAN
    [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$([System.IO.Path]::GetDirectoryName($cmakePath))", "User")
}

if ($envPath -notcontains [System.IO.Path]::GetDirectoryName($ninjaPath)) {
    Print-Colored "Adding Ninja to PATH..." $CYAN
    [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$([System.IO.Path]::GetDirectoryName($ninjaPath))", "User")
}

Print-Colored "Setup complete. Please restart your terminal or IDE to apply changes." $GREEN

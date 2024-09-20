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
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $Command $($Args -join ' ') }`"" -Verb RunAs -Wait
    } else {
        & $Command @Args
    }
}

# Function to refresh the environment variables
function Refresh-EnvironmentVariables {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Display banner
Print-Colored @"
 /██   /██  /██████      /██████   /███████
|  ██ /██/ /██__  ██    /██__  ██ /██_____/
 \  ████/ | ██  \ ██   | ██  \__/|  ██████
  >██  ██ | ██  | ██   | ██       \____  ██
 /██/\  ██|  ██████//██| ██       /███████/
|__/  \__/ \______/|__/|__/      |_______/
---------------------------------------------
 github.com/incredimo | aghil@xo.rs | xo.rs
---------------------------------------------
INSTALLING PYTHON 3.12.6 ON WINDOWS
---------------------------------------------
"@ $CYAN

# Define Python version and download URL
$pythonVersion = "3.12.6"
$pythonUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-amd64.exe"
$installerPath = "$env:TEMP\python-$pythonVersion-amd64.exe"

# Download Python installer
Print-Colored "Downloading Python $pythonVersion installer..." $CYAN
try {
    Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -ErrorAction Stop
} catch {
    Print-Colored "Failed to download Python installer: $($_.Exception.Message)" $RED
    exit 1
}

# Verify the download
if (-not (Test-Path $installerPath)) {
    Print-Colored "Python installer not found at $installerPath" $RED
    exit 1
}

# Install Python
Print-Colored "Installing Python $pythonVersion..." $CYAN
$installArgs = "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0"
try {
    $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru -ErrorAction Stop
    if ($process.ExitCode -ne 0) {
        throw "Installation process exited with code $($process.ExitCode)"
    }
} catch {
    Print-Colored "Failed to install Python $pythonVersion`: $($_.Exception.Message)" $RED
    Print-Colored "Please check if you have sufficient permissions and try running the script as administrator." $YELLOW
    exit 1
}
Print-Colored "Python $pythonVersion has been successfully installed." $GREEN
Refresh-EnvironmentVariables

# Verify Python installation
if (Command-Exists "python") {
    Print-Colored "Verifying Python installation..." $CYAN
    $pythonVersionOutput = (python --version 2>&1).ToString()
    Print-Colored "Python version: $pythonVersionOutput" $GREEN
} else {
    Print-Colored "Python command not found. Checking default installation paths..." $YELLOW
    $possiblePaths = @(
        "${env:ProgramFiles}\Python312\python.exe",
        "${env:ProgramFiles(x86)}\Python312\python.exe",
        "${env:LocalAppData}\Programs\Python\Python312\python.exe"
    )
    $foundPath = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $foundPath = $path
            Print-Colored "Python found at: $foundPath" $GREEN
            break
        }
    }
    if (-not $foundPath) {
        Print-Colored "Python installation verification failed. Please check your installation and PATH." $RED
        exit 1
    }
}

# Verify pip installation
Print-Colored "Checking if pip is installed..." $CYAN
if (Command-Exists "pip") {
    $pipVersionOutput = (pip --version 2>&1).ToString()
    Print-Colored "pip version: $pipVersionOutput" $GREEN
} else {
    Print-Colored "pip not found. It should have been installed with Python. Please check your installation." $RED
    exit 1
}

# Update PATH environment variable
Print-Colored "Updating PATH environment variable..." $CYAN
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Path
if (-not $pythonPath) {
    $pythonPath = $foundPath
}
$pythonDir = [System.IO.Path]::GetDirectoryName($pythonPath)
$scriptsDir = Join-Path $pythonDir "Scripts"
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notcontains $pythonDir) {
    [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$pythonDir", "User")
}

if ($userPath -notcontains $scriptsDir) {
    [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptsDir", "User")
}

# Set PYTHONHOME environment variable
Print-Colored "Setting PYTHONHOME environment variable..." $CYAN
[System.Environment]::SetEnvironmentVariable("PYTHONHOME", $pythonDir, "User")

# Clean up
Remove-Item $installerPath -Force

# Final message
Print-Colored "Python $pythonVersion installation and setup complete." $GREEN
Print-Colored "Please restart your terminal or IDE to apply the changes to your environment variables." $YELLOW
Print-Colored "You can now use Python and pip from the command line." $CYAN
Print-Colored "If you encounter any issues, please ensure you're running this script as an administrator." $YELLOW

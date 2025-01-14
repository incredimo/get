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

# Function to refresh the environment variables
function Refresh-EnvironmentVariables {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
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
INSTALLING PROTOCOL BUFFERS (PROTOC) ON WINDOWS
---------------------------------------------
" $CYAN

# Step 1: Check if `protoc` is already installed
Print-Colored "Checking if `protoc` is installed..." $CYAN
if (Command-Exists "protoc") {
    Print-Colored "`protoc` is already installed." $GREEN
    protoc --version
    exit 0
}

# Step 2: Download and install `protoc`
Print-Colored "Downloading `protoc`..." $CYAN
$protocUrl = "https://github.com/protocolbuffers/protobuf/releases/download/v26.1/protoc-26.1-win64.zip"
$protocZip = "$env:TEMP\protoc.zip"
$protocDir = "$env:TEMP\protoc"

# Download the protoc binary
Invoke-WebRequest -Uri $protocUrl -OutFile $protocZip

# Extract the zip file
Print-Colored "Extracting `protoc`..." $CYAN
Expand-Archive -Path $protocZip -DestinationPath $protocDir -Force

# Step 3: Add `protoc` to the system PATH
Print-Colored "Adding `protoc` to PATH..." $CYAN
$protocBinPath = "$protocDir\bin"
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

if ($envPath -notcontains $protocBinPath) {
    [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$protocBinPath", "Machine")
    Refresh-EnvironmentVariables
    Print-Colored "`protoc` has been added to PATH." $GREEN
} else {
    Print-Colored "`protoc` is already in PATH." $YELLOW
}

# Step 4: Verify installation
Print-Colored "Verifying `protoc` installation..." $CYAN
if (Command-Exists "protoc") {
    Print-Colored "`protoc` has been successfully installed!" $GREEN
    protoc --version
} else {
    Print-Colored "Failed to install `protoc`. Please check the logs and try again." $RED
    exit 1
}

# Step 5: Clean up temporary files
Print-Colored "Cleaning up temporary files..." $CYAN
Remove-Item -Path $protocZip -Force
Remove-Item -Path $protocDir -Recurse -Force

Print-Colored "Setup complete. Please restart your terminal or IDE to apply changes." $GREEN
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
INSTALLING FLUTTER ON WINDOWS
---------------------------------------------
"@ $CYAN

# Define Flutter version and download URL
$flutterVersion = "3.16.5"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$flutterVersion-stable.zip"
$zipPath = "$env:TEMP\flutter_windows_$flutterVersion-stable.zip"
$installDir = "C:\src\flutter"

# Download Flutter ZIP
Print-Colored "Downloading Flutter $flutterVersion..." $CYAN
try {
    Invoke-WebRequest -Uri $flutterUrl -OutFile $zipPath -ErrorAction Stop
} catch {
    Print-Colored "Failed to download Flutter: $($_.Exception.Message)" $RED
    exit 1
}

# Verify the download
if (-not (Test-Path $zipPath)) {
    Print-Colored "Flutter ZIP not found at $zipPath" $RED
    exit 1
}

# Extract Flutter
Print-Colored "Extracting Flutter to $installDir..." $CYAN
try {
    if (Test-Path $installDir) {
        Remove-Item -Path $installDir -Recurse -Force
    }
    Expand-Archive -Path $zipPath -DestinationPath "C:\src" -Force
} catch {
    Print-Colored "Failed to extract Flutter: $($_.Exception.Message)" $RED
    exit 1
}

# Update PATH environment variable
Print-Colored "Updating PATH environment variable..." $CYAN
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notcontains $installDir) {
    [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir\bin", "User")
}

Refresh-EnvironmentVariables

# Verify Flutter installation
if (Command-Exists "flutter") {
    Print-Colored "Verifying Flutter installation..." $CYAN
    flutter --version

    Print-Colored "Running Flutter doctor..." $CYAN
    flutter doctor
} else {
    Print-Colored "Flutter command not found. Please check your installation and PATH." $RED
    exit 1
}

# Install Android SDK
Print-Colored "Installing Android SDK..." $CYAN
$androidSdkUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidSdkZip = "$env:TEMP\commandlinetools-win-latest.zip"
$androidSdkDir = "$env:LOCALAPPDATA\Android\Sdk"

Invoke-WebRequest -Uri $androidSdkUrl -OutFile $androidSdkZip
Expand-Archive -Path $androidSdkZip -DestinationPath $androidSdkDir -Force

# Set ANDROID_HOME environment variable
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkDir, "User")

# Update PATH for Android SDK tools
$sdkManager = "$androidSdkDir\cmdline-tools\latest\bin"
$platformTools = "$androidSdkDir\platform-tools"
[System.Environment]::SetEnvironmentVariable("Path", "$userPath;$sdkManager;$platformTools", "User")

Refresh-EnvironmentVariables

# Accept Android SDK licenses
Print-Colored "Accepting Android SDK licenses..." $CYAN
echo y | sdkmanager --licenses

# Install necessary Android SDK components
Print-Colored "Installing Android SDK components..." $CYAN
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Install Visual Studio Code (optional)
$installVSCode = Read-Host "Do you want to install Visual Studio Code? (y/n)"
if ($installVSCode -eq 'y') {
    Print-Colored "Installing Visual Studio Code..." $CYAN
    $vsCodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
    $vsCodeInstaller = "$env:TEMP\vscode_installer.exe"
    Invoke-WebRequest -Uri $vsCodeUrl -OutFile $vsCodeInstaller
    Start-Process -FilePath $vsCodeInstaller -ArgumentList "/VERYSILENT /MERGETASKS=!runcode" -Wait
    Remove-Item $vsCodeInstaller -Force
}

# Clean up
Remove-Item $zipPath -Force
Remove-Item $androidSdkZip -Force

# Final message
Print-Colored "Flutter installation and setup complete." $GREEN
Print-Colored "Please restart your terminal or IDE to apply the changes to your environment variables." $YELLOW
Print-Colored "You can now use Flutter from the command line." $CYAN
Print-Colored "If you encounter any issues, please ensure you're running this script as an administrator." $YELLOW
Print-Colored "Next steps:" $CYAN
Print-Colored "1. Run 'flutter doctor' to check for any remaining issues." $CYAN
Print-Colored "2. Create a new Flutter project with 'flutter create my_app'" $CYAN
Print-Colored "3. Navigate to your project directory and run 'flutter run' to test your setup." $CYAN

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

# Function to remove specified registry keys if they exist
function Remove-RegistryKey {
    param (
        [string]$RegistryPath
    )
    if (Test-Path $RegistryPath) {
        Remove-Item -Path $RegistryPath -Recurse -Force
        Print-Colored "Removed: $RegistryPath" $GREEN
    } else {
        Print-Colored "Path not found: $RegistryPath" $YELLOW
    }
}

# Function to add "Open with VS Code" to the context menu
function Add-VSCodeContextMenu {
    param (
        [string]$RegistryPath,
        [string]$Command
    )
    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force
        Set-ItemProperty -Path $RegistryPath -Name "(Default)" -Value "Open with VS Code"
        New-Item -Path "$RegistryPath\command" -Force
        Set-ItemProperty -Path "$RegistryPath\command" -Name "(Default)" -Value $Command
        Print-Colored "Added: Open with VS Code to $RegistryPath" $GREEN
    } else {
        Print-Colored "Open with VS Code already exists at $RegistryPath" $YELLOW
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
MODIFYING RIGHT-CLICK CONTEXT MENU
---------------------------------------------
" $CYAN

# Paths to remove from the context menu
$pathsToRemove = @(
    "HKEY_CLASSES_ROOT\*\shell\Open with Visual Studio",
    "HKEY_CLASSES_ROOT\*\shell\Open Git GUI here",
    "HKEY_CLASSES_ROOT\*\shell\Open Git Bash here",
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Open with Visual Studio",
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Open Git GUI here",
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Open Git Bash here"
)

# Remove the specified context menu items
Print-Colored "Removing specified context menu items..." $CYAN
foreach ($path in $pathsToRemove) {
    Remove-RegistryKey -RegistryPath $path
}

# Check if Visual Studio Code is installed by looking for the executable path
$vsCodeExecutable = "C:\Program Files\Microsoft VS Code\Code.exe"
if (-Not (Test-Path $vsCodeExecutable)) {
    $vsCodeExecutable = "C:\Users\$env:USERNAME\AppData\Local\Programs\Microsoft VS Code\Code.exe"
}

if (Test-Path $vsCodeExecutable) {
    Print-Colored "Visual Studio Code found at $vsCodeExecutable" $CYAN

    # Define the path to the new context menu item
    $vsCodePathFile = "HKEY_CLASSES_ROOT\*\shell\Open with VS Code"
    $vsCodePathDir = "HKEY_CLASSES_ROOT\Directory\Background\shell\Open with VS Code"

    # Add "Open with VS Code" for files and directories
    Add-VSCodeContextMenu -RegistryPath $vsCodePathFile -Command "`"$vsCodeExecutable`" `"%1`""
    Add-VSCodeContextMenu -RegistryPath $vsCodePathDir -Command "`"$vsCodeExecutable`" `"%V`""
} else {
    Print-Colored "Visual Studio Code executable not found. Please ensure Visual Studio Code is installed." $RED
}

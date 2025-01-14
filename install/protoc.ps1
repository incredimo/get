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

# Display banner
Print-Colored "
██████╗ ██████╗  ██████╗ ████████╗ ██████╗  ██████╗
██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝
██████╔╝██████╔╝██║   ██║   ██║   ██║   ██║██║     
██╔═══╝ ██╔══██╗██║   ██║   ██║   ██║   ██║██║     
██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╗
╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝
------------------------------------------------
INSTALLING PROTOCOL BUFFERS ON WINDOWS
------------------------------------------------
" $CYAN

# Create installation directory
$installDir = "$env:LOCALAPPDATA\protoc"
$binDir = "$installDir\bin"

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
    New-Item -ItemType Directory -Path $binDir | Out-Null
}

# Check if protoc is already installed
if (Command-Exists "protoc") {
    $currentVersion = (protoc --version).Split(" ")[1]
    Print-Colored "Current protoc version: $currentVersion" $CYAN
}

# Get latest protoc version from GitHub
Print-Colored "Checking latest protoc version..." $CYAN
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/protocolbuffers/protobuf/releases/latest"
$latestVersion = $releases.tag_name -replace 'v', ''

if ($currentVersion -ne $latestVersion) {
    Print-Colored "Installing protoc version $latestVersion..." $CYAN
    
    # Download protoc
    $zipFile = "protoc-$latestVersion-win64.zip"
    $downloadUrl = "https://github.com/protocolbuffers/protobuf/releases/download/v$latestVersion/$zipFile"
    
    try {
        Print-Colored "Downloading protoc..." $CYAN
        Invoke-WebRequest -Uri $downloadUrl -OutFile "$installDir\$zipFile"
        
        # Extract the zip file
        Print-Colored "Extracting files..." $CYAN
        Expand-Archive -Path "$installDir\$zipFile" -DestinationPath $installDir -Force
        
        # Add to PATH if not already present
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$binDir*") {
            Print-Colored "Adding protoc to PATH..." $CYAN
            [Environment]::SetEnvironmentVariable(
                "Path",
                "$userPath;$binDir",
                "User"
            )
            $env:Path = "$env:Path;$binDir"
        }
        
        # Cleanup
        Remove-Item "$installDir\$zipFile" -Force
        
        # Verify installation
        Print-Colored "Verifying protoc installation..." $CYAN
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (Command-Exists "protoc") {
            Print-Colored "protoc has been successfully installed:" $GREEN
            protoc --version
        } else {
            Print-Colored "protoc installation verification failed." $RED
            exit 1
        }
        
    } catch {
        Print-Colored "Error during installation: $_" $RED
        exit 1
    }
} else {
    Print-Colored "protoc is already up-to-date." $GREEN
}

# Print final instructions
Print-Colored "
Installation completed successfully!
You may need to restart your terminal for PATH changes to take effect.
To verify installation, open a new terminal and run: protoc --version
" $GREEN
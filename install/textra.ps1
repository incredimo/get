# Variables
$DownloadUrl = "https://github.com/u-tra/textra/raw/master/release/textra.exe"
$FileName = "textra.exe"
$AppName = "textra" # Name of your application

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

# Function to download the file
function Download-File {
    param (
        [string]$Url,
        [string]$OutFile
    )
    Print-Colored "Downloading $OutFile from $Url..." $CYAN
    Invoke-WebRequest -Uri $Url -OutFile $OutFile
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to download $OutFile." $RED
        exit 1
    }
}

# Function to run the downloaded file with "install" argument
function Run-DownloadedFile {
    param (
        [string]$FileName
    )
    Print-Colored "Running $FileName with argument 'install'..." $CYAN
    Start-Process -FilePath $FileName -ArgumentList "install" -Wait
    if ($LASTEXITCODE -ne 0) {
        Print-Colored "Failed to run $FileName." $RED
        exit 1
    }
}

# Display banner
Print-Colored "
 |██   |██  |██████      |██████   |███████
|  ██ |██/ |██  ██    |██  ██ |██__/
 \  ████/ | ██  \ ██   | ██  \/|  ██████
  >██  ██ | ██  | ██   | ██       \__  ██
 |██/\  ██|  ██████|██|| ██       |███████/
|/  \/ \__/|/|/      |___/
---------------------------------------------
 github.com/incredimo | aghil@xo.rs | xo.rs
---------------------------------------------
INSTALLING $AppName ON WINDOWS
---------------------------------------------
" $CYAN

# Start the process
Download-File -Url $DownloadUrl -OutFile $FileName
Run-DownloadedFile -FileName $FileName
Print-Colored "$AppName installation completed successfully." $GREEN

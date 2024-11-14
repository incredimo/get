# Configuration - All paths under user directory
$userBase = Join-Path $env:USERPROFILE "pdf_extractor_deps"
$vcpkgPath = Join-Path $userBase "vcpkg"
$llvmPath = Join-Path $userBase "llvm"
$cmakePath = Join-Path $userBase "cmake"
$env:VCPKG_ROOT = $vcpkgPath

# Create base directory
New-Item -ItemType Directory -Path $userBase -Force | Out-Null

# Function to download file
function Download-File($Url, $OutputPath) {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($Url, $OutputPath)
}

# Function to extract zip
function Extract-Zip($ZipPath, $DestinationPath) {
    Expand-Archive -Path $ZipPath -DestinationPath $DestinationPath -Force
    Remove-Item $ZipPath
}

Write-Host "Setting up PDF Extractor dependencies (User Level with LLVM)..." -ForegroundColor Green

# Install LLVM if not present
if (-not (Test-Path $llvmPath)) {
    Write-Host "Downloading and extracting LLVM..." -ForegroundColor Yellow
    $llvmUrl = "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.0/LLVM-16.0.0-win64.exe"
    $llvmInstaller = Join-Path $userBase "llvm-installer.exe"
    Download-File $llvmUrl $llvmInstaller
    
    # Extract LLVM using 7-Zip (part of Windows 10+)
    $tempPath = Join-Path $userBase "llvm-temp"
    Start-Process -Wait -FilePath $llvmInstaller -ArgumentList "/S", "/D=$llvmPath"
    Remove-Item $llvmInstaller
}

# Install CMake if not present
if (-not (Test-Path $cmakePath)) {
    Write-Host "Downloading and extracting CMake..." -ForegroundColor Yellow
    $cmakeUrl = "https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-windows-x86_64.zip"
    $cmakeZip = Join-Path $userBase "cmake.zip"
    Download-File $cmakeUrl $cmakeZip
    Extract-Zip $cmakeZip $cmakePath
}

# Add tools to PATH
$env:PATH = "$llvmPath\bin;$cmakePath\bin;$env:PATH"

# Install Rust if not present
if (-not (Get-Command "rustc" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Rust..." -ForegroundColor Yellow
    $rustupInit = Join-Path $userBase "rustup-init.exe"
    Download-File "https://win.rustup.rs/x86_64" $rustupInit
    
    # Install Rust with MSVC toolchain
    Start-Process -Wait -FilePath $rustupInit -ArgumentList "-y", "--no-modify-path"
    Remove-Item $rustupInit
    
    # Set up LLVM toolchain
    rustup toolchain install stable-x86_64-pc-windows-gnu
    rustup default stable-x86_64-pc-windows-gnu
}

# Setup vcpkg if not present
if (-not (Test-Path $vcpkgPath)) {
    Write-Host "Setting up vcpkg..." -ForegroundColor Yellow
    $vcpkgZip = Join-Path $userBase "vcpkg.zip"
    Download-File "https://github.com/microsoft/vcpkg/archive/refs/heads/master.zip" $vcpkgZip
    Extract-Zip $vcpkgZip $userBase
    Move-Item (Join-Path $userBase "vcpkg-master") $vcpkgPath
    
    # Configure vcpkg to use LLVM
    $env:CC = "clang"
    $env:CXX = "clang++"
    
    Push-Location $vcpkgPath
    cmd /c "call bootstrap-vcpkg.bat"
    Pop-Location
}

# Install required libraries through vcpkg
Write-Host "Installing required libraries..." -ForegroundColor Yellow
$libraries = @(
    "leptonica:x64-windows",
    "tesseract:x64-windows",
    "zlib:x64-windows",
    "libpng:x64-windows",
    "libjpeg-turbo:x64-windows"
)

foreach ($lib in $libraries) {
    Write-Host "Installing $lib..." -ForegroundColor Yellow
    & "$vcpkgPath\vcpkg" install $lib --host-triplet x64-windows
}

# Create environment variable script
$envScript = @"
# Environment variables for PDF Extractor
`$env:VCPKG_ROOT = "$vcpkgPath"
`$env:LEPTONICA_INCLUDE_PATH = "$vcpkgPath\installed\x64-windows\include"
`$env:LEPTONICA_LINK_PATHS = "$vcpkgPath\installed\x64-windows\lib"
`$env:LEPTONICA_LINK_LIBS = "leptonica-1.82.0"
`$env:TESSERACT_INCLUDE_PATH = "$vcpkgPath\installed\x64-windows\include"
`$env:TESSERACT_LINK_PATHS = "$vcpkgPath\installed\x64-windows\lib"
`$env:PATH = "$llvmPath\bin;$cmakePath\bin;$vcpkgPath\installed\x64-windows\bin;`$env:PATH"
`$env:CC = "clang"
`$env:CXX = "clang++"
"@

$envScriptPath = Join-Path $userBase "set_env.ps1"
$envScript | Out-File -FilePath $envScriptPath -Encoding utf8

# Create .cargo/config.toml
$cargoConfig = @"
[target.x86_64-pc-windows-gnu]
linker = "clang"
ar = "llvm-ar"
rustflags = [
    "-C", "link-arg=-fuse-ld=lld",
    "-L", "native=$vcpkgPath/installed/x64-windows/lib",
    "-l", "leptonica-1.82.0",
    "-l", "tesseract41",
]

[env]
VCPKG_ROOT = "$vcpkgPath"
"@

# Create .cargo directory if it doesn't exist
$cargoConfigPath = Join-Path $env:USERPROFILE ".cargo"
if (-not (Test-Path $cargoConfigPath)) {
    New-Item -ItemType Directory -Path $cargoConfigPath | Out-Null
}

# Write cargo config
$cargoConfigFile = Join-Path $cargoConfigPath "config.toml"
$cargoConfig | Out-File -FilePath $cargoConfigFile -Encoding utf8

Write-Host @"

Setup completed! To use the PDF extractor:

1. Run this before building (every new terminal):
   . '$envScriptPath'

2. Update your Cargo.toml to include:
   [package]
   name = "pdf_extractor"
   version = "0.1.0"
   edition = "2021"

   [dependencies]
   lopdf = "0.31"
   pdf-extract = "0.7"
   image = "0.24"
   tesseract = "0.13"
   clap = { version = "4.4", features = ["derive"] }
   anyhow = "1.0"
   tempfile = "3.8"
   rayon = "1.8"
   chrono = "0.4"

   [build-dependencies]
   vcpkg = "0.2"

3. Navigate to your project directory and build:
   cargo clean
   cargo build

All dependencies are installed in:
$userBase

You can remove this directory to clean up everything if needed.
"@ -ForegroundColor Green

# Load the environment variables in the current session
. $envScriptPath

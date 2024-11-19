# build.ps1
$userBase = Join-Path $env:USERPROFILE "build_essentials"
$vcpkgPath = Join-Path $userBase "vcpkg"
$llvmPath = Join-Path $userBase "llvm"
$cmakePath = Join-Path $userBase "cmake"

# Function for colored output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Function to check if a vcpkg package is installed
function Test-VcpkgPackage {
    param (
        [string]$package,
        [string]$triplet
    )
    $installedPackages = & "$vcpkgPath\vcpkg.exe" list
    return $installedPackages -match "${package}:${triplet}"
}

# Function to install vcpkg package if not present
function Install-VcpkgPackageIfNeeded {
    param (
        [string]$package,
        [string]$triplet
    )
    
    if (-not (Test-VcpkgPackage -package $package -triplet $triplet)) {
        Write-ColorOutput Cyan "Installing $package for $triplet..."
        $process = Start-Process -FilePath "$vcpkgPath\vcpkg.exe" -ArgumentList "install", "${package}:${triplet}" -NoNewWindow -PassThru -Wait
        if ($process.ExitCode -ne 0) {
            Write-ColorOutput Red "Failed to install $package"
            return $false
        }
    } else {
        Write-ColorOutput Green "$package:$triplet already installed"
    }
    return $true
}

# Set environment variables first for vcpkg
$env:VCPKG_ROOT = $vcpkgPath

# Check and install required packages
Write-ColorOutput Yellow "Checking vcpkg packages..."
$requiredPackages = @(
    @{name="leptonica"; triplet="x64-windows-static"},
    @{name="tesseract"; triplet="x64-windows-static"},
    @{name="zlib"; triplet="x64-windows-static"},
    @{name="libpng"; triplet="x64-windows-static"},
    @{name="libjpeg-turbo"; triplet="x64-windows-static"}
)

$needsInstall = $false
foreach ($pkg in $requiredPackages) {
    if (-not (Test-VcpkgPackage -package $pkg.name -triplet $pkg.triplet)) {
        $needsInstall = $true
        break
    }
}

# Only reinstall if needed
if ($needsInstall) {
    Write-ColorOutput Yellow "Some packages are missing. Installing required packages..."
    $success = $true
    foreach ($pkg in $requiredPackages) {
        if (-not (Install-VcpkgPackageIfNeeded -package $pkg.name -triplet $pkg.triplet)) {
            $success = $false
            break
        }
    }

    if (-not $success) {
        Write-ColorOutput Red "Failed to install required packages. Exiting."
        exit 1
    }
} else {
    Write-ColorOutput Green "All required packages are already installed"
}

# Set environment variables
Write-ColorOutput Yellow "Setting up environment variables..."
$env:LIBCLANG_PATH = "$llvmPath\bin"
$env:LEPTONICA_INCLUDE_PATH = "$vcpkgPath\installed\x64-windows-static\include"
$env:LEPTONICA_LINK_PATHS = "$vcpkgPath\installed\x64-windows-static\lib"
$env:LEPTONICA_LINK_LIBS = "leptonica-1.82.0"
$env:TESSERACT_INCLUDE_PATH = "$vcpkgPath\installed\x64-windows-static\include"
$env:TESSERACT_LINK_PATHS = "$vcpkgPath\installed\x64-windows-static\lib"
$env:PATH = "$libclangPath;$llvmPath\bin;$cmakePath\bin;$vcpkgPath\installed\x64-windows-static\bin;$env:PATH"
$env:CARGO_PROFILE_DEV_BUILD_OVERRIDE_DEBUG = "true"
$env:RUST_BACKTRACE = "full"

# Build with live output
Write-ColorOutput Yellow "`nStarting build process..."
Write-ColorOutput Cyan "Running: cargo build --features static"

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "cargo"
$pinfo.Arguments = "build --features static"
$pinfo.UseShellExecute = $false
$pinfo.RedirectStandardOutput = $true
$pinfo.RedirectStandardError = $true
$pinfo.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $pinfo
$process.Start() | Out-Null

$outputHandler = {
    if (-not [String]::IsNullOrEmpty($EventArgs.Data)) {
        $line = $EventArgs.Data
        if ($line -match "^error") {
            Write-ColorOutput Red $line
        } elseif ($line -match "^warning") {
            Write-ColorOutput Yellow $line
        } elseif ($line -match "Compiling|Finished|Running") {
            Write-ColorOutput Green $line
        } else {
            Write-ColorOutput White $line
        }
    }
}

$errorHandler = {
    if (-not [String]::IsNullOrEmpty($EventArgs.Data)) {
        Write-ColorOutput Red $EventArgs.Data
    }
}

$outputEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outputHandler
$errorEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $errorHandler

$process.BeginOutputReadLine()
$process.BeginErrorReadLine()
$process.WaitForExit()

$outputEvent | Unregister-Event
$errorEvent | Unregister-Event

if ($process.ExitCode -eq 0) {
    Write-ColorOutput Green "`nBuild completed successfully!"
    
    $targetPath = Join-Path (Get-Location) "target\debug"
    $exeName = (Get-ChildItem -Path "Cargo.toml" | 
                Select-String -Pattern '^\s*name\s*=\s*"([^"]+)"' | 
                ForEach-Object { $_.Matches.Groups[1].Value })
    
    if ($exeName) {
        Write-ColorOutput Cyan "`nExecutable location:"
        Write-ColorOutput White "$targetPath\$exeName.exe"
        Write-ColorOutput Cyan "`nTo run the extractor:"
        Write-ColorOutput White ".\target\debug\$exeName.exe -i <input.pdf> -o <output_dir> [--ocr]"
    }
} else {
    Write-ColorOutput Red "`nBuild failed!"
    Write-ColorOutput Yellow "`nDiagnostic Information:"
    Write-ColorOutput White "LIBCLANG_PATH: $env:LIBCLANG_PATH"
    Write-ColorOutput White "TESSERACT_INCLUDE_PATH: $env:TESSERACT_INCLUDE_PATH"
    Write-ColorOutput White "TESSERACT_LINK_PATHS: $env:TESSERACT_LINK_PATHS"
    Write-ColorOutput White "VCPKG_ROOT: $env:VCPKG_ROOT"
    Write-ColorOutput White "PATH: $env:PATH"
}

if ($process.ExitCode -ne 0) {
    Write-ColorOutput Yellow "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

@REM hide unnecessary output
ECHO OFF
@REM restart as admin if not already
Echo Checking for admin rights
if "%1" == "UACPrompt" goto gotAdmin
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "UACPrompt", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B    

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B
    
    
:gotAdmin
@REM install chocolatey
goto install_choco
@REM install git
goto install_git

@REM install flutter
goto install_flutter

:install_choco
@REM check if chocolatey is already installed
Echo Checking if Chocolatey is already installed
choco list --local-only | findstr chocolatey
if %ERRORLEVEL% EQU 0 goto choco_installed
@REM install chocolatey
Echo Installing Chocolatey
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"


:choco_installed
Echo Chocolatey installed successfully
goto install_git

:install_git
@REM check if git is already installed
Echo Checking if Git is already installed
choco list --local-only | findstr git
if %ERRORLEVEL% EQU 0 goto git_installed
@REM install git with no context menu integration
Echo Installing Git
choco install -y git --params "/NoShellIntegration"
@REM add git to path
Echo Adding Git to system path
setx /M PATH "%PATH%;C:\Program Files\Git\cmd"
@REM add git to user path
Echo Adding Git to user path
setx /M PATH "%PATH%;C:\Program Files\Git\cmd" /USER

:git_installed
Echo Git installed successfully
goto install_flutter

:install_flutter
@REM check if flutter is already installed
Echo Checking if Flutter is already installed
choco list --local-only | findstr flutter
if %ERRORLEVEL% EQU 0 goto flutter_installed
Echo Installing Flutter SDK
choco install -y flutter



:flutter_installed
Echo Flutter SDK installed successfully
@REM add flutter to path
git config --global --add safe.directory C:/tools/flutter
@REM add flutter and dart to user and system path
Echo Adding flutter and dart to system path
setx /M PATH "%PATH%;C:\tools\flutter\bin"
setx /M PATH "%PATH%;C:\tools\flutter\bin" /USER
setx /M PATH "%PATH%;C:\tools\flutter\bin\cache\dart-sdk\bin"
setx /M PATH "%PATH%;C:\tools\flutter\bin\cache\dart-sdk\bin" /USER
@REM add pub to user and system path
Echo Adding pub to system path
setx /M PATH "%PATH%;C:\tools\flutter\bin\cache\dart-sdk\bin\cache\dart-sdk\bin"
setx /M PATH "%PATH%;C:\tools\flutter\bin\cache\dart-sdk\bin\cache\dart-sdk\bin" /USER


@REM run flutter doctor
flutter doctor



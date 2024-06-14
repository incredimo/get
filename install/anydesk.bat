@echo off
ECHO OFF
@REM Hide unnecessary output

@REM Check if AnyDesk is already downloaded
set "URL=https://download.anydesk.com/AnyDesk.exe"
set "FILENAME=AnyDesk.exe"
set "DESTINATION=%USERPROFILE%\Downloads\%FILENAME%"

if not exist "%DESTINATION%" (
    echo Downloading AnyDesk...
    powershell -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%DESTINATION%'"
) else (
    echo AnyDesk already downloaded.
)

@REM Run AnyDesk
echo Running AnyDesk...
start "" "%DESTINATION%"

@REM Display banner
echo.
echo  /██   /██  /██████      /██████   /███████
echo |  ██ /██/ /██__  ██    /██__  ██ /██_____/
echo  \  ████/ | ██  \ ██   | ██  \__/|  ██████ 
echo   >██  ██ | ██  | ██   | ██       \____  ██
echo  /██/\  ██|  ██████//██| ██       /███████/
echo |__/  \__/ \______/|__/|__/      |_______/ 
echo ---------------------------------------------
echo  github.com/incredimo | aghil@xo.rs | xo.rs
echo ---------------------------------------------
echo  INSTALLING POCKETBASE ON DEBIAN
echo ---------------------------------------------

exit /B

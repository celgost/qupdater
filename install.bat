@echo off
setlocal

echo Installing qUpdater...
echo.

:: Source paths - where this .bat is located
set "SOURCE_DIR=%~dp0"
set "SOURCE_EXE=%SOURCE_DIR%qUpdater.exe"

:: If relaunched from UAC, only perform the Program Files copy in the elevated process.
:: The original unelevated process writes HKCU so startup is registered for the launching user.
if /I "%~1"=="/programfilescopy" goto copyProgramFiles

:: Check if qUpdater.exe exists next to this .bat
if not exist "%SOURCE_EXE%" (
	echo Error: qUpdater.exe not found in the same folder as this .bat!
	echo Expected location:
	echo %SOURCE_EXE%
	echo.
	echo Press any key to exit...
	pause >nul
	exit /b 1
)

:menu
echo Choose installation type:
echo.
echo 1 - Install to Program Files
echo     Copies qUpdater.exe to Program Files and autoruns from there.
echo     Requires administrator permission.
echo.
echo 2 - Run from this folder
echo     Keeps qUpdater.exe where it is and autoruns from this location.
echo     No administrator permission required.
echo.
set /p INSTALL_CHOICE="Enter choice [1/2]: "

if "%INSTALL_CHOICE%"=="1" goto installProgramFiles
if "%INSTALL_CHOICE%"=="2" goto installCurrentFolder

echo.
echo Invalid choice. Please enter 1 or 2.
echo.
goto menu


:installProgramFiles
echo.
echo Selected: Install to Program Files

set "INSTALL_DIR=%ProgramFiles%\qUpdater"
set "TARGET_EXE=%INSTALL_DIR%\qUpdater.exe"

:: Check admin rights
fltmc >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
	echo Requesting administrative privileges to copy qUpdater.exe...
	goto UACPrompt
)

call :copyProgramFiles
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

goto addRegistry


:installCurrentFolder
echo.
echo Selected: Run from this folder

set "TARGET_EXE=%SOURCE_EXE%"

echo.
echo Stopping any running instances...
taskkill /F /IM qUpdater.exe 2>nul

goto addRegistry


:addRegistry
echo.
echo Adding qUpdater to startup registry...
:: Keep this HKCU write in the launching process so Program Files installs
:: autorun for the user who started the installer, not the elevated account.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "qUpdater" /t REG_SZ /d "\"%TARGET_EXE%\"" /f

if %ERRORLEVEL% NEQ 0 (
	echo Error: Failed to add registry entry.
	echo.
	echo Press any key to exit...
	pause >nul
	exit /b 1
)

echo.
echo Verifying registry entry...
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "qUpdater" >nul

if %ERRORLEVEL% NEQ 0 (
	echo Error: Failed to verify registry entry.
	echo.
	echo Press any key to exit...
	pause >nul
	exit /b 1
)

echo.
echo Installation complete!
echo qUpdater autorun path:
echo %TARGET_EXE%

echo.
echo Starting qUpdater...
start "" "%TARGET_EXE%"

echo.
echo Press any key to close this window...
pause >nul
exit /b 0


:copyProgramFiles
if not defined INSTALL_DIR set "INSTALL_DIR=%ProgramFiles%\qUpdater"
if not defined TARGET_EXE set "TARGET_EXE=%INSTALL_DIR%\qUpdater.exe"
echo.
echo Stopping any running instances...
taskkill /F /IM qUpdater.exe 2>nul

echo.
echo Creating installation directory:
echo %INSTALL_DIR%
mkdir "%INSTALL_DIR%" 2>nul

echo.
echo Copying qUpdater.exe...
copy /Y "%SOURCE_EXE%" "%TARGET_EXE%" >nul

if %ERRORLEVEL% NEQ 0 (
	echo Error: Failed to copy qUpdater.exe to:
	echo %TARGET_EXE%
	echo.
	echo Press any key to exit...
	pause >nul
	exit /b 1
)

exit /b 0


:UACPrompt
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '/programfilescopy' -Verb RunAs -Wait"

if %ERRORLEVEL% NEQ 0 (
	echo Error: Administrative copy was cancelled or failed.
	echo.
	echo Press any key to exit...
	pause >nul
	exit /b 1
)

if not exist "%TARGET_EXE%" (
	echo Error: qUpdater.exe was not copied to:
	echo %TARGET_EXE%
	echo.
	echo Press any key to exit...
	pause >nul
	exit /b 1
)

goto addRegistry

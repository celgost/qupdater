@echo off
setlocal EnableExtensions

echo Uninstalling qUpdater...
echo.

set "RUN_KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
set "VALUE_NAME=qUpdater"
set "PROGRAM_DIR=%ProgramFiles%\qUpdater"
set "PROGRAM_EXE=%PROGRAM_DIR%\qUpdater.exe"

:: Elevated branch - only used for deleting Program Files folder
if /I "%~1"=="/deleteProgramFiles" goto deleteProgramFiles


echo Reading startup registry entry...

set "AUTORUN_PATH="

for /f "tokens=1,2,*" %%A in ('reg query "%RUN_KEY%" /v "%VALUE_NAME%" 2^>nul ^| findstr /I "%VALUE_NAME%"') do (
	if /I "%%A"=="%VALUE_NAME%" (
		if /I "%%B"=="REG_SZ" (
			set "AUTORUN_PATH=%%C"
		)
	)
)

:: Remove quotes from registry path if present.
:: This line is intentionally outside parenthesized blocks because paths may contain parentheses.
set "AUTORUN_PATH=%AUTORUN_PATH:"=%"

echo.
if not defined AUTORUN_PATH goto noAutorunPath

echo Found autorun path:
echo %AUTORUN_PATH%
goto afterAutorunPathEcho

:noAutorunPath
echo No autorun registry entry found.

:afterAutorunPathEcho

echo.
echo Stopping qUpdater if running...
taskkill /F /IM qUpdater.exe 2>nul


echo.
echo Removing startup registry entry...
reg delete "%RUN_KEY%" /v "%VALUE_NAME%" /f >nul 2>&1

if %ERRORLEVEL% NEQ 0 goto registryRemoveWarning
echo Registry entry removed successfully.
goto afterRegistryRemove

:registryRemoveWarning
echo Registry entry was not found or could not be removed.
echo It may have already been removed.

:afterRegistryRemove


:: Compare outside parenthesized blocks because AUTORUN_PATH may contain parentheses.
if /I "%AUTORUN_PATH%"=="%PROGRAM_EXE%" goto programFilesInstallFound

goto notProgramFilesInstall


:programFilesInstallFound
echo.
echo qUpdater was installed in Program Files.
echo Program Files folder should be removed:
echo %PROGRAM_DIR%
echo.

:: Check admin rights
fltmc >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto UACPrompt

goto deleteProgramFiles


:notProgramFilesInstall
echo.
echo qUpdater was not installed in Program Files, or no Program Files autorun was found.
echo Only the startup registry entry was removed.
echo.
echo Uninstall complete.
echo.
echo Press any key to close this window...
pause >nul
exit /b 0


:deleteProgramFiles
echo.
echo Removing Program Files installation...

echo Stopping qUpdater if running...
taskkill /F /IM qUpdater.exe 2>nul

if not exist "%PROGRAM_DIR%" goto programFilesFolderMissing

rmdir /S /Q "%PROGRAM_DIR%"

if exist "%PROGRAM_DIR%" goto programFilesRemoveFailed

echo Program Files folder removed successfully.
goto uninstallDone


:programFilesFolderMissing
echo Program Files folder was not found.
goto uninstallDone


:programFilesRemoveFailed
echo Error: Failed to remove folder:
echo %PROGRAM_DIR%
echo.
echo You may need to close qUpdater or delete the folder manually.
echo.
echo Press any key to close this window...
pause >nul
exit /b 1


:uninstallDone
echo.
echo Uninstall complete.
echo.
echo Press any key to close this window...
pause >nul
exit /b 0


:UACPrompt
echo Requesting administrative privileges to remove Program Files folder...
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin_qUpdater_uninstall.vbs"
echo UAC.ShellExecute "%~s0", "/deleteProgramFiles", "", "runas", 1 >> "%temp%\getadmin_qUpdater_uninstall.vbs"
"%temp%\getadmin_qUpdater_uninstall.vbs"
del "%temp%\getadmin_qUpdater_uninstall.vbs" 2>nul
exit /b

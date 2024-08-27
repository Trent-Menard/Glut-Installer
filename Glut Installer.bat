@ECHO OFF
TITLE Glut Installer

REM Created by Trent Menard

NET FILE >NUL 2>&1
IF NOT "%ERRORLEVEL%" == "0" (
	COLOR 4
	ECHO [FATAL]: Insufficient permissions, please run as an Administrator (right click, run as Admin^).
	ECHO.
	PAUSE
	EXIT
)

SET copyFilesPath=%~dp0\Dependencies\CopyFiles.ps1
POWERSHELL -ExecutionPolicy Bypass -File "%copyFilesPath%"
PAUSE
@echo off
title COMPUTER BILD-Tool --- Windows-Turbo: OS ohne Autostarts rebooten

mode con lines=75 cols=155

2>NUL reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings" /v "Enabled" >NUL
if %errorlevel%==1 GOTO LOS
if %errorlevel%==0 GOTO disabled

:disabled

reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings" /v "Enabled" | findstr "1" >NUL
if %errorlevel%==1 GOTO disabled
if %errorlevel%==0 GOTO LOS

:disabled
echo Der Windows Script Host wurde deaktiviert. Aktivieren Sie ihn wieder und starten Sie dieses Tool dann neu.
echo.
pause
exit



:LOS






2>NUL mkdir "%windir%\BatchGotAdmin"
if '%errorlevel%' == '0' (
  rmdir "%windir%\BatchGotAdmin" & goto gotAdmin 
) else ( goto UACPrompt )

:UACPrompt
echo Es sind Administrator-Rechte erforderlich.
echo Best„tigen Sie folgende Abfrage per Klick auf "Ja".
echo.
timeout /t 3 >NUL

    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute %0, "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"      
    CD /D "%~dp0"




reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce /v "Filesystem-Autostarts_recovery" > NUL 2>NUL
if %errorlevel%==1 GOTO a
if %errorlevel%==0 GOTO b

:a

if exist "%userprofile%\AppData\Roaming\Filesystem-Autostarts_recovery.cmd" goto cleanup_fortfahren
if NOT exist "%userprofile%\AppData\Roaming\Filesystem-Autostarts_recovery.cmd" goto b


:cleanup_fortfahren

echo Das Tool wurde schon einmal benutzt. Wollen Sie alle technischen Rckst„nde entfernen?
echo Hierfr drcken Sie bitte eine beliebige Taste.
echo Wenn Sie nichts tun, entfernt dieses Tool seine Spuren sogleich automatisch.
timeout /t 5 > NUL
goto cleanup


:b


>%temp%\meldung.vbs (
  echo WScript.Quit _
  echo    MsgBox("Wollen Sie Windows jetzt einmalig ohne Autostarts neu starten? Künftig booten sie dann wieder mit."^& vbCrLf ^&" "^& vbCrLf ^&"", _
  echo    vbYesNo Or vbDefaultButton1 Or vbExclamation, _
  echo    "Windows im Turbo-Modus neu booten?"^)
)
wscript %temp%\meldung.vbs

if %errorlevel%==7 nein
if %errorlevel%==6 GOTO ja

:nein
del %temp%\meldung.vbs
exit

:ja
del %temp%\meldung.vbs
REM Ordner anlegen, Flag anlegen, Dateisystem-Autostarts verschieben

md %AppData%\Autostart-Backup
move "%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\*" %AppData%\Autostart-Backup

echo move %AppData%\Autostart-Backup\* "%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" > %AppData%\Filesystem-Autostarts_recovery.cmd

reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce /v Filesystem-Autostarts_recovery /t REG_SZ /d %AppData%\Filesystem-Autostarts_recovery.cmd /f



REM Registryteile sichern und diese danach l?schen (HKCU-only)


reg export HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run %AppData%\HKCU-Autostarts.reg

reg export HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run %AppData%\HKLM-Autostarts.reg

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run /f
reg delete HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run /f
reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run /f
reg add HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run /f






SCHTASKS /Create /TN "HKLM" /sc once /st 00:00 /TR "C:\Windows\system32\reg.exe import ""%AppData%\HKLM-Autostarts.reg""" /RU %username% /RL HIGHEST /f



echo Set Shell = CreateObject("WScript.Shell") > %temp%\hklm.vbs
echo DesktopPath = Shell.SpecialFolders("Desktop") >> %temp%\hklm.vbs
echo Set link = Shell.CreateShortcut(DesktopPath ^& "\HKLM.lnk") >> %temp%\hklm.vbs
echo link.Arguments = "/RUN /TN ""HKLM""" >> %temp%\hklm.vbs
echo link.TargetPath = "C:\Windows\System32\schtasks.exe" >> %temp%\hklm.vbs
echo link.Save >> %temp%\hklm.vbs

call %temp%\hklm.vbs
del %temp%\hklm.vbs


move %userprofile%\Desktop\HKLM.lnk %AppData%\HKLM.lnk



echo reg import %AppData%\HKCU-Autostarts.reg >> %AppData%\Filesystem-Autostarts_recovery.cmd
echo start %AppData%\HKLM.lnk >> %AppData%\Filesystem-Autostarts_recovery.cmd


shutdown -r -t 01
exit

:cleanup

del %AppData%\HKCU-Autostarts.reg
del %AppData%\HKLM-Autostarts.reg
del %AppData%\HKLM.lnk
del %AppData%\Filesystem-Autostarts_recovery.cmd
SCHTASKS /Delete /TN "HKLM" /f
rd rd %AppData%\Autostart-Backup /s /q







@echo off
setlocal enabledelayedexpansion
title VIPPortscanner0.1
color 07

echo.
echo VIPPortscanner0.1 by AC
echo.

set /p "target=Target IP: "
if "%target%"=="" set target=127.0.0.1

set /p "ports=Ports (single/range/comma): "
if "%ports%"=="" set ports=1-1024

set /p "timeout=Timeout (ms): "
if "%timeout%"=="" set timeout=1000

set /p "export=Export (y/n): "
if /i "%export%"=="y" set "exportfile=scan_%target%.txt"

echo.
echo Resolving %target%...
for /f "tokens=2 delims=[]" %%a in ('ping -n 1 %target% ^| find "["') do set "ip=%%a"
if "%ip%"=="" (
    for /f "tokens=2 delims=:" %%a in ('ping -n 1 %target% ^| find "Reply"') do (
        set "temp=%%a"
        set "ip=!temp: =!"
    )
)
if "%ip%"=="" (
    echo Failed to resolve.
    pause
    exit /b
)
echo Resolved to %ip%
echo.

set "portlist="
echo %ports% | find "-" >nul
if %errorlevel%==0 (
    for /f "tokens=1,2 delims=-" %%a in ("%ports%") do (
        for /l %%i in (%%a,1,%%b) do set "portlist=!portlist! %%i"
    )
) else (
    echo %ports% | find "," >nul
    if %errorlevel%==0 ( set "portlist=%ports:,= %" ) else ( set "portlist=%ports%" )
)

echo Scanning %ip%...
echo.

if defined exportfile (
    echo VIPPortscanner0.1 by AC > %exportfile%
    echo Target: %target% (%ip%) >> %exportfile%
    echo Started: %date% %time% >> %exportfile%
    echo. >> %exportfile%
    echo PORT STATE SERVICE >> %exportfile%
    echo ---- ----- ------- >> %exportfile%
)

set open=0
set closed=0
set total=0

for %%p in (%portlist%) do (
    set /a total+=1
    set "port=%%p"
    set "state=closed"
    set "service=unknown"

    powershell -command "$tcp = New-Object System.Net.Sockets.TcpClient; $result = $tcp.BeginConnect('%ip%', %port%, $null, $null); $wait = $result.AsyncWaitHandle.WaitOne(%timeout%); if($wait){ $tcp.EndConnect($result); $tcp.Close(); Write-Host 'open' } else { Write-Host 'closed' }" > temp.txt

    set /p "result="<temp.txt

    if /i "!result!"=="open" (
        set "state=open"
        set /a open+=1
        if !port!==21 set service=FTP
        if !port!==22 set service=SSH
        if !port!==23 set service=Telnet
        if !port!==25 set service=SMTP
        if !port!==53 set service=DNS
        if !port!==80 set service=HTTP
        if !port!==110 set service=POP3
        if !port!==143 set service=IMAP
        if !port!==443 set service=HTTPS
        if !port!==445 set service=SMB
        if !port!==3306 set service=MySQL
        if !port!==3389 set service=RDP
        if !port!==5432 set service=PostgreSQL
        if !port!==5900 set service=VNC
        if !port!==8080 set service=HTTP-Alt
        if !port!==8443 set service=HTTPS-Alt
        echo !port! OPEN !service!
        if defined exportfile echo !port! OPEN !service! >> %exportfile%
    ) else (
        set /a closed+=1
        echo !port! CLOSED ---
        if defined exportfile echo !port! CLOSED --- >> %exportfile%
    )
)

del temp.txt 2>nul

echo.
echo =========================
echo Scan Complete
echo Target: %target% (%ip%)
echo Total: %total%
echo Open: %open%
echo Closed: %closed%
echo Timeout: %timeout%ms
echo =========================

if defined exportfile (
    echo ========================= >> %exportfile%
    echo Scan Complete >> %exportfile%
    echo Total: %total% >> %exportfile%
    echo Open: %open% >> %exportfile%
    echo Closed: %closed% >> %exportfile%
    echo Timeout: %timeout%ms >> %exportfile%
    echo ========================= >> %exportfile%
    echo.
    echo Exported to %exportfile%
)

echo.
pause
exit /b
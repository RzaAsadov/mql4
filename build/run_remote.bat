@echo off
set arg1=%1
set arg2=%2
echo "Running %arg1%"
cd "C:\Users\mt4_development\MT4\%arg2%"
taskkill /F /FI "WINDOWTITLE eq %arg2%*"
del /Q C:\Users\mt4_development\MT4\%arg2%\logs\*.*
psexec -d C:\Users\mt4_development\MT4\%arg2%\terminal.exe /portable config_%arg1%.txt  

@echo off
echo "Compiling %1"
set arg1=%1
set arg2=%2

IF EXIST "z:\home\mt4_development\MT4\%arg2%\MQL4\Indicators\%arg1%.log" (
    del "z:\home\mt4_development\MT4\%arg2%\MQL4\Indicators\%arg1%.log"
)
"z:\home\mt4_development\MT4\%arg2%\metaeditor.exe" /log /portable /compile:"z:\home\mt4_development\MT4\%arg2%\MQL4\Indicators\%arg1%.mq4" 

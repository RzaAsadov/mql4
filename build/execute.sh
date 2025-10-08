#!/bin/bash

echo "C:\\Users\\mt4_development\\MT4\\$2\\psexec -d C:\\Users\\mt4_development\\MT4\\$2\\MQL4\\Experts\\run_remote.bat $1 $2"

ssh zrid@mt4dev1 -p 5566 "C:\\Users\\mt4_development\\MT4\\$2\\psexec -d C:\\Users\\mt4_development\\MT4\\$2\\MQL4\\Experts\\run_remote.bat $1 $2"

exit 0
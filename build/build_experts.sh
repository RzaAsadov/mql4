#!/bin/bash

sudo su mt4_development -c "cp -rf /home/zrid/Hero/mq4/ea/$1.mq4 /home/mt4_development/MT4/$2/MQL4/Experts/"
echo -e "**** 1. Sources copied ****"

sudo su mt4_development -c "cp -rf /home/zrid/Hero/mq4/Include/TradersTube/* /home/mt4_development/MT4/$2/MQL4/Include/TradersTube"
echo -e "**** 2. Library Sources copied ****"

sudo su mt4_development -c "cp -rf /home/zrid/Hero/mq4/build/* /home/mt4_development/MT4/$2/MQL4/build"
echo -e "**** 3. Build scripts copied ****"

sudo su mt4_development -c "cp -rf /home/zrid/Hero/mq4/Include/libs/* /home/mt4_development/MT4/$2/MQL4/Include/libs/"
echo -e "**** 4. Standart Libraries copied ****\n"


sudo su mt4_development -c "/usr/bin/wine /home/mt4_development/MT4/$2/MQL4/build/compile_ea.bat $1 $2 &> /dev/null &"
sudo su mt4_development -c "/usr/bin/dos2unix /home/mt4_development/MT4/$2/MQL4/Experts/$1.log &> /dev/null &"

cat /home/mt4_development/MT4/$2/MQL4/Experts/$1.log | grep error

date


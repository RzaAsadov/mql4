#!/bin/bash

ssh mt4_development@mt4dev1 del C:\\Users\\mt4_trade_readers\\MT4\\OSPREY_5083022\\MQL4\\Experts\\TradersTubeBackTester.ex4
ssh mt4_development@mt4dev1 copy C:\\Users\\mt4_development\\MT4\\101108944\\MQL4\\Experts\\TradersTubeBackTester.ex4 C:\\Users\\mt4_trade_readers\\MT4\\OSPREY_5083022\\MQL4\\Experts\\
echo "TraderTube BackTester install to OSPREY Account" 

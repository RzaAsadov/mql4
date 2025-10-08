#!/bin/bash

ssh mt4_development@mt4dev1 del C:\\Users\\mt4_trade_readers\\MT4\\OSPREY_5083022\\MQL4\\Experts\\TradersTubeTradeReader.ex4
ssh mt4_development@mt4dev1 copy C:\\Users\\mt4_development\\MT4\\101108944\\MQL4\\Experts\\TradersTubeTradeReader.ex4 C:\\Users\\mt4_trade_readers\\MT4\\OSPREY_5083022\\MQL4\\Experts\\
echo "TraderTube TRADE READER installed to OSPREY Account (Trade Readers)" 


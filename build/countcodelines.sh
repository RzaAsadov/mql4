#!/bin/bash
echo -n "mql code lines: "; find . -name "*.mq4" -exec grep -v -w "~" -c {} \; | awk '{s+=$1} END {print s}'
echo -n "mql code lines: "; find ./extensions -name "*.mqh" -exec grep -v -w "~" -c {} \; | awk '{s+=$1} END {print s}'


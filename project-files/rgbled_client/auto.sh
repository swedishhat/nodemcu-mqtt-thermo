#!/bin/bash
for i in $( ls lua ); do
    ../../tools/luatool/luatool/luatool.py -p /dev/ttyUSB1 -f $PWD/lua/$i
done
screen /dev/ttyUSB1 9600

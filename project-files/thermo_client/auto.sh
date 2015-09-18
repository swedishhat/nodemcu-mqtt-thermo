#!/bin/bash
for i in $( ls lua ); do
    ../../tools/luatool/luatool/luatool.py -f $PWD/lua/$i -v
done
screen /dev/ttyUSB0 9600

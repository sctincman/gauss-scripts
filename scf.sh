#!/bin/sh
#grabs the last energy output from a log file

filename=$1

grep "SCF Done" ${filename} | tail -n 1 | sed -r "s/.*E\([[:alnum:]]*\) \= *(-?[0-9]*\.[0-9]*) *.*$/\1/"



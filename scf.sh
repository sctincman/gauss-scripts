#!/bin/sh

readonly PROGNAME=$(basename $0)
readonly ARGN=${#}
readonly FILENAME=$1

usage() {
    echo "Usage: $PROGNAME output.log"
    echo '    Outputs the final energy from a Gaussian logfile'
}

main() {

    if [ $ARGN -eq 0 ]; then
	usage
	exit 0
    fi

    grep "SCF Done" ${FILENAME} \
	| tail -n 1 \
	| sed -r "s/.*E\([[:alnum:]]*\) \= *(-?[0-9]*\.[0-9]*) *.*$/\1/"
}

main



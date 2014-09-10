#!/bin/sh

readonly PROGNAME=$(basename $0)
readonly ARGN=${#}
readonly FINAL=${1}
readonly INITIAL=${2}
readonly HARTREE=627.509469

usage() {
    echo "Usage: $PROGNAME final.log initial.log"
    echo '    Computes the energy difference and converts to kcal/mol'
    echo '    [final,initial].log are Gaussian log files for initial and final states'
}

find_scf_energy () {
    local file=$1

    grep "SCF Done" ${file} \
	| tail -n 1 \
	| sed -r "s/.*E\([[:alnum:]]*\) \= *(-?[0-9]*\.[0-9]*) *.*$/\1/"
}

main() {
    if [ $ARGN -lt 2 ] ; then
	usage
	exit 0
    fi

    #todo, input check :P

    echo "scale=6;($(find_scf_energy $FINAL) - $(find_scf_energy $INITIAL)) * $HARTREE" \
	| bc -q
}

main

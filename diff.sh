#!/bin/sh
#compute difference between two files, convert from hartree to kcal/mol

if [ -z ${SCRIPT_DIR} ] ; then
	SCRIPT_DIR="/home/guest/scripts"
fi

#Usage
if [ ${#} -eq 0 ] ; then
    echo 'Usage: diff.sh final.log initial.log'
    echo '    computes the energy difference and converts to kcal/mol'
    echo '    final.log/initial.log are Gaussian log files for initial and final states'
    exit 0
fi

#todo, input check :P

echo "scale=6;($(${SCRIPT_DIR}/scf.sh ${1}) - $(${SCRIPT_DIR}/scf.sh ${2}))*627.509469" | bc -q

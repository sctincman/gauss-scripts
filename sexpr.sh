#!/bin/sh

# Util script for formatting input files for my chemutils.rkt script

#check if these variables are set explicitly, if not set them to default
if [ -z ${SCRIPT_DIR} ] ; then
    SCRIPT_DIR="/home/guest/scripts"
fi  


if [ ${#} -eq 0 ] ; then
    echo 'Usage: sexpr file1.log [file2.log file3.log ...]'
    echo '    file[n].log is a Gaussian output logfile (with #p and pop=regular keywords)'
    exit 0
fi

for filename in $@ ; do
    NAME=$(basename $filename .log)
    echo -e "(\"${NAME}\" (\"MOs\" . ($(${SCRIPT_DIR}/scrape.sh ${filename} | grep -E "[0-9]+[[:space:]]+[OV]{1}[[:space:]]+-?[0-9]*\.{1}[0-9]+.*eV$" | sed -r 's/[[:space:]]+([0-9]+)[[:space:]]+[OV]{1}[[:space:]]+(-?[0-9]*\.{1}[0-9]+).*eV$/    (\1 \2)/'))))"
done



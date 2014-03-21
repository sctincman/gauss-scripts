#!/bin/sh
# just a shortcut to avoid copying and pasting this stupid command over and over and over again
# this one should (ideally) generate cubes for any MOs scrape gives us

#TODO distiniguish between alpha/beta orbitals
## ATM, uses only orbital number, which (I think) cubegen assumes is alpha orbital if not specified

if [ ${#} -eq 0 ] ; then
    echo 'Usage: cubeMO file.[f]chk '
    echo '    file.[f]chk is a Gaussian checkpoint file'
    echo '        will convert to a formatted checkpoint file automatically'
    echo '    will place in a subdirectory named "(filename)-cubes'
    echo '        this can be overridden with the CUBE_DIR variable'
    exit 0
fi

if [ -z ${SCRIPT_DIR} ] ; then
	SCRIPT_DIR="/home/guest/scripts"
fi

filename=$1

if [ ${filename#*\.} != "fchk" ] ; then
    echo "File not a formatted checkpoint file" 1>&2
    if [ ${filename#*\.} = "chk" ] ; then
	echo "File is a binary checkpoint file. Converting"  1>&2
	formchk ${filename} "${filename%\.chk}.fchk"
	filename="${filename%\.chk}.fchk"
    else
	exit 1
    fi
fi

#worried this will pollute the directories too much, allow a sub directory, and create
if [ -z ${CUBE_DIR} ] ; then
    CUBE_DIR=./${filename%\.fchk}-cubes
fi

if [ ! -d ${CUBE_DIR} ] ; then
    mkdir -p ${CUBE_DIR}
fi

levels=$(grep -E '[[:space:]]+[0-9]+[[:space:]]+[OV]{1}[[:space:]]+-?[0-9]*\.{1}[0-9]+[[:space:]]+[0-9]*\.{1}[0-9]+[[:space:]]*$' ${filename%\.fchk}.log | sed -r 's:^[[:space:]]*([0-9]+)[[:space:]]+[OV].*$:\1:' | sort -u)

if [ ${filename#*\.} = "fchk" ] ; then
#    cubegen 0 MO=Homo "${filename}" "${filename%\.fchk}-HOMO.cube" 0 h
    for n in ${levels} ; do
	cubegen 0 MO=${n} "${filename}" "${CUBE_DIR}/${filename%\.fchk}-MO${n}.cube" 0 h
    done
fi

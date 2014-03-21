#!/bin/sh
# just a shortcut to avoid copying and pasting this stupid command over and over and over again

filename=$1

if [ "${filename#*\.}" != "fchk" ] ; then
    echo "File not a formatted checkpoint file" 1>&2
    if [ "${filename#*\.}" = "chk" ] ; then
	echo "File is a binary checkpoint file. Converting"  1>&2
	formchk ${filename} "${filename%\.chk}.fchk"
	filename="${filename%\.chk}.fchk"
    fi
fi

if [ "${filename#*\.}" = "fchk" ] ; then
    cubegen 0 MO=Homo "${filename}" "${filename%\.fchk}-HOMO.cube" 0 h
    cubegen 0 MO=Lumo "${filename}" "${filename%\.fchk}-LUMO.cube" 0 h
fi



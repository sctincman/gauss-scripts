#!/bin/sh

readonly PROGNAME=$(basename $0)
readonly ARGN=${#}

readonly FILENAME=$1
readonly SPINFILE=$2

usage() {
    echo "Usage: $PROGNAME input.[f]chk [spin.cube]"
    echo "    Generates cubefile for the spindensity from output."
    echo "    input.[f]chk is the checkpoint file from Gaussian."
    echo "    spin.cube is the optional output filename."
    echo "    (By default, will output to input-spin.cube)"
    echo "    cubgen requires fchk files, but this will convert chk files"
    echo "    for you."
}

get_fchkfile() {
    local filename=$1

    if [ "${filename#*\.}" = "fchk" ]; then
	echo $filename
    else
	if [ "${filename#*\.}" = "chk" ]; then
	    echo "File is a binary checkpoint file. Converting"  1>&2
	    formchk $filename
	    echo "${filename%\.chk}.fchk"
	else
	    echo "Error: Not a checkpoint file" 1>&2
	    exit 1
	fi
    fi
}

main() {
    if [ $ARGN -eq 0 -o $ARGN -gt 2 ] ; then
	usage
	exit 0
    fi

    local fchkfile=$(get_fchkfile $FILENAME)

    local spincube=${fchkfile%\.fchk}-spin.cube

    if [ $ARGN -eq 3 ]; then
	spincube=${SPINFILE}
    fi

    cubegen 0 Spin "$fchkfile" "${spincube}" 0 h
}

main

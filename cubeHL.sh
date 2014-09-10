#!/bin/sh

readonly PROGNAME=$(basename $0)
readonly ARGN=${#}

readonly FILENAME=$1
readonly HOMOFILE=$2
readonly LUMOFILE=$3

usage() {
    echo "Usage: $PROGNAME input.[f]chk [homo.cube lumo.cube]"
    echo "    Generates cubefiles for the HOMO/LUMO orbitals from output."
    echo "    input.[f]chk is the checkpoint file from Gaussian."
    echo "    [homo,lumo].cube are the optional output filenames."
    echo "    (By default, will output to input-[HOMO,LUMO].cube)"
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
    if [ $ARGN -eq 0 -o $ARGN -ne 1 -a $ARGN -ne 3 ] ; then
	usage
	exit 0
    fi

    local fchkfile=$(get_fchkfile $FILENAME)

    local homocube=${fchkfile%\.fchk}-HOMO.cube
    local lumocube=${fchkfile%\.fchk}-LUMO.cube

    if [ $ARGN -eq 3 ]; then
	homocube=${HOMOFILE}
	lumocube=${LUMOFILE}
    fi

    cubegen 0 MO=Homo "$fchkfile" "${homocube}" 0 h
    cubegen 0 MO=Lumo "$fchkfile" "${lumocube}" 0 h
}

main

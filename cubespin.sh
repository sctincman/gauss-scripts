#!/bin/sh
# just a shortcut to avoid copying and pasting this stupid command over and over and over again

if [ ${#} -eq 0 ] ; then
    echo 'Usage: cubespin file.[f]chk '
    echo '    file.[f]chk is a Gaussian checkpoint file'
    echo '        will convert to a formatted checkpoint file automatically'
    echo '    will place in a subdirectory named "(filename)-cubes'
    echo '        this can be overridden with the CUBE_DIR variable'
    exit 0
fi

filename=$1

if [ ${filename#*\.} != "fchk" ] ; then
    echo "File not a formatted checkpoint file" 1>&2
    if [ ${filename#*\.} = "chk" ] ; then
	echo "File is a binary checkpoint file. Converting"  1>&2
	formchk ${filename} "${filename%\.chk}.fchk"
	filename="${filename%\.chk}.fchk"
    fi
fi

if [ -z ${CUBE_DIR} ] ; then
    CUBE_DIR=.
fi

if [ ! -d ${CUBE_DIR} ] ; then
    mkdir -p ${CUBE_DIR}
fi

if [ ${filename#*\.} = "fchk" ] ; then
    cubegen 0 Spin "${filename}" "${CUBE_DIR}/${filename%\.fchk}-spin.cube" 0 h
fi



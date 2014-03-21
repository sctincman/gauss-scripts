#!/bin/sh
# Formats a gaussian input file for ONIOM calculations
# Requires three files
#   1) The raw gaussin com file (cartesian only for now...)
#   2) An xyz file of all the high level/QM atoms
#   3) An xyz of all link atoms/LA (for the boundry between high and low level, for now assumes H replacement)

#IFS='                 
#'; a=( $( < oniom.txt ) ); for match in $a; do sed -ir 's/\('${match}'\) L/\1 H/' oniom.bak; done

#Usage
if [ ${#} -eq 0 ] ; then
    echo 'Usage: oniom.sh comfile [[QM File] [LA file]]'
    echo '    comfile is the raw gaussian input file'
    echo '    QM file is the xyz file of all high level atoms (default is ${comfile}-QM.xyz)'
    echo '    LA file is the xyz file of all link atoms (default is ${comfile}-LA.xyz)'
    exit 0
fi

comfile=$1

if [ ! -e $comfile ] ; then
    echo "File does not exist" 1>&2
    exit 1
fi

if [ ${comfile#*\.} != "com" ] ; then
    echo "File is not a gaussian input file" 1>&2
    exit 1
fi

#directory to use for temp files
TMP="/tmp"

basename=${comfile%\.*}

if [ -e "${basename}-QM.xyz" ] ; then
    qmfile="${basename}-QM.xyz"
elif [ ${#} -ge 2 -a -e "${2}" ] ; then
    qmfile=${2}
else
    echo "No QM file found/specified" 1>&2
    exit 1
fi

if [ -e "${basename}-LA.xyz" ] ; then
    lafile="${basename}-LA.xyz"
elif [ ${#} -ge 3 -a -e "${3}" ] ; then
    lafile=${3}
else
    echo "No LA file found/specified" 1>&2
    exit 1
fi

#copy .com file to /tmp and work on that, copy back here when done
tmpfile="${TMP}/${comfile}"
cp $comfile $tmpfile

#Append all lines matching a atom coordinate with an L (low level)
sed -ri 's/[A-Z][a-z]?( +\-?[0-9]+\.[0-9]+){3}/& L/' $tmpfile

#For all lines in the QM file (matching a molecules coordinate), replace the L with an H
IFS='
'
#for line in `< "${qmfile}"` ; do
for line in `grep -E '[A-Z][a-z]?( +\-?[0-9]+\.[0-9]+){3}' "${qmfile}"` ; do
    sed -ri 's/('${line}') L/\1 H/' $tmpfile
done
#For all lines in the LA file (matching a molecules coordinate), append an H
for line in `grep -E '[A-Z][a-z]?( +\-?[0-9]+\.[0-9]+){3}' "${lafile}"` ; do
    sed -ri 's/'${line}' L/& H/' $tmpfile
done

#by this point, should be sucessful, move the tmpfile back
mv $tmpfile $comfile



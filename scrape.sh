#!/bin/sh
# A quick util script to pull out E-level info, and convert from Hartree to eV

#Usage
if [ ${#} -eq 0 ] ; then
    echo 'Usage: scrape file1.log [file2.log file3.log ...]'
    echo '    file[n].log is a Gaussian output logfile (with #p and pop=regular keywords)'
    exit 0
fi

for filename in $@ ; do
    echo "Scraping ${filename}:"

    LINES=$(grep -E '[[:space:]]+[0-9]+[[:space:]]+[OV]{1}[[:space:]]+-?[0-9]*\.{1}[0-9]+[[:space:]]+[0-9]*\.{1}[0-9]+[[:space:]]*$' $filename)

    if [ -z "${LINES}" ] ; then
	echo "    No Orbital lines in log file! (did you use '#p' and 'pop=regular'?)"
    else

	echo "    Orbital     Occ/Virt         Energy"

	IFS='
'
	for line in ${LINES} ; do
	    NUM=$(echo $line | sed -r 's:.* (-?[0-9]*\.{1}[0-9]+).*-?[0-9]*\.{1}[0-9]+.*:\1:')
	    RESULT=$(echo "scale=6;$NUM*27.211" | bc -q)
	    echo "   $line" | sed -r 's:(-?[0-9]*\.{1}[0-9]+).*:'"${RESULT}"' eV:'
	done
    fi
done



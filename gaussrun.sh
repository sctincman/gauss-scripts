#!/bin/sh

logdir="./logs"

if [ ! -d ${logdir} ] ; then
	mkdir -p ${logdir}
fi

logfile="${logdir}/gaussrun-`date +%m-%d-%y`.log"

echo -e "\nStarting run on `date`:" | tee -a $logfile 1>&2
echo " Running Jobs:" | tee -a $logfile 1>&2
for file in $@ ; do
    if [ -e $file -a "${file#*\.}" = "com" ] ; then
	echo "  $file" | tee -a $logfile 1>&2
    else
	echo "   Error: $file does not exist or is not a Gaussian input file" | tee -a $logfile 1>&2
	exit 1
    fi
done
echo -e "\n" | tee -a $logfile 1>&2
for file in $@ ; do
   echo -e "    -------\n    Starting file $file at `date`" | tee -a $logfile 1>&2
   g09 < ${file} > ${file%\.*}.log
   #echo -e "    $file Done with status $?" | tee -a $logfile 1>&2
   if [ $? -eq 0 ] ; then
       echo -e "    $file finished successfully at `date`" | tee -a $logfile 1>&2
   else
       echo -e "    $file failed at `date`" | tee -a $logfile 1>&2
   fi
done
echo -e "All Done.\n\n" | tee -a $logfile 1>&2



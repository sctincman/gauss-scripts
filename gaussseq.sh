#! /bin/sh

echo "Running Jobs:" >> gaussrun.log
echo $@ >> gaussrun.log
for file in $@ ; do
    echo "Starting file $file at `date`" >> gaussrun.log
    g09 <<END> $file-r.log
%Chk=${file}-r
# HF/6-31G(d) FOpt
@${file}/N
 
--Link1--
%Chk=${file}-r
%NoSave
# MP2/6-31+G(d,p) SP Guess=Read Geom=AllCheck
END
    echo "$file Done with status $status" >> gaussrun.log
done
echo "All Done." >> gaussrun.log


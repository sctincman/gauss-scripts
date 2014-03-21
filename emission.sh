#!/bin/sh
# This script takes an initial .gau input file (charge, mult, and coords) and generates and runs the necessary gaussian com files for a full solvent-dependent emission determination
# This script relies on "skeleton" gaussian com files. The defaults are emission-[step].com.skel in the current directory, or if not found the ones in SKEL_DIR.
## Example, say 6-31+G* is way too much for you, just do
### cp '/home/guest/scripts/emission-*.com.skel' (or just the specific step you want to change)
## and change those files with your editor of choice
## the script checks the current working directory first before defaulting back to the ones in $SKEL_DIR

# This is based on the "State-specific solvated emission" example on the Gaussian 09 manual page for SCRF keyword

# For now, this just runs the calculations, it'd be nice to have another utility that automatically does the workup, but that's for another time.

#check if these variables are set explicitly, if not set them to default
if [ -z ${SKEL_DIR} ] ; then
	SKEL_DIR="/home/guest/scripts/emission-skel"
fi

if [ -z ${SCRIPT_DIR} ] ; then
	SCRIPT_DIR="/home/guest/scripts"
fi

#usage prompt if no arguments given
if [ ${#} -eq 0 ] ; then
    echo 'Usage: emission.sh gaufile solvent'
    echo '    gaufile is the gaussian input file of the starting structure'
    echo '    solvent is a keyword passed to SCRF as the solvent to be used'
    exit 0
fi

#input file, and log file (uses the root of the input filename)
gaufile=$1
solvent=$2
logfile="emission-${gaufile%\.*}.log"

#testing for precesence of skel files in the current directory. If none, then use the default
if [ -e "./emission-01-ground.com.skel" ] ; then
    step1="./emission-01-ground.com.skel"
else
    step1="${SKEL_DIR}/emission-01-ground.com.skel"
fi

if [ -e "./emission-02-vertical.com.skel" ] ; then
    step2="./emission-02-vertical.com.skel"
else
    step2="${SKEL_DIR}/emission-02-vertical.com.skel"
fi

if [ -e "./emission-03-solvstate.com.skel" ] ; then
    step3="./emission-03-solvstate.com.skel"
else
    step3="${SKEL_DIR}/emission-03-solvstate.com.skel"
fi

if [ -e "./emission-04-S1-opt.com.skel" ] ; then
    step4="./emission-04-S1-opt.com.skel"
else
    step4="${SKEL_DIR}/emission-04-S1-opt.com.skel"
fi

if [ -e "./emission-05-S1-freq.com.skel" ] ; then
    step5="./emission-05-S1-freq.com.skel"
else
    step5="${SKEL_DIR}/emission-05-S1-freq.com.skel"
fi

if [ -e "./emission-06-S1-solv.com.skel" ] ; then
    step6="./emission-06-S1-solv.com.skel"
else
    step6="${SKEL_DIR}/emission-06-S1-solv.com.skel"
fi

if [ -e "./emission-07-emit.com.skel" ] ; then
    step7="./emission-07-emit.com.skel"
else
    step7="${SKEL_DIR}/emission-07-emit.com.skel"
fi

#make sure our input file actually exists before starting
if [ -e $gaufile -a ${gaufile#*\.} = "gau" ] ; then
    #log start to logfile
    echo "Staring emission on input file: $gaufile" | tee -a $logfile 1>&2

    #the root of the input filename, used for all output files
    root=${gaufile%\.*}
    # our initial groundstate opt, title is a variable that is expanded in the skel file
    title="${root} groundstate geom opt - emission"
    # concatonate the skeleton com file and the input file, and evaluate to fill in variables, then pipe into gaussian
    echo -e "$(eval "echo -e \"$(sed -r 's/^([0-9]+) *([0-9]+)$/\1 \2/' ${gaufile} | grep -E '^[[:alnum:]]' | cat ${step1} - )\"")\n\n"  | g09 > ${root}-01-ground.log

    #test if the last command (g09) succeeded, and continue if it has
    if [ $? -eq 0 ] ; then
	#record success in logfile
	echo "${root}-01-ground finished sucessfully at `date`" | tee -a $logfile 1>&2
	
	cp ${root}-01-ground.chk ${root}-02-vertical.chk
	title="${root} vertical excitation - emission"
	echo "$(eval "echo \"$(cat ${step2})\"")" | g09 > ${root}-02-vertical.log

	if [ $? -eq 0 ] ; then
	    	#record success in logfile
	    echo "${root}-02-vertical finished sucessfully at `date`" | tee -a $logfile 1>&2
	
	    cp ${root}-02-vertical.chk ${root}-03-solvstate.chk
	    title="${root} state specific solvation for excitation - emission"
	    echo "$(eval "echo \"$(cat ${step3})\"")" | g09 > ${root}-03-solvstate.log

	    if [ $? -eq 0 ] ; then
	    	#record success in logfile
		echo "${root}-03-solvstate finished sucessfully at `date`" | tee -a $logfile 1>&2
		
		cp ${root}-03-solvstate.chk ${root}-04-S1-opt.chk
		title="${root} excited state geom opt - emission"
		echo "$(eval "echo \"$(cat ${step4})\"")" | g09 > ${root}-04-S1-opt.log

		if [ $? -eq 0 ] ; then
	    	    #record success in logfile
		    echo "${root}-04-S1-opt finished sucessfully at `date`" | tee -a $logfile 1>&2
		    
		    cp ${root}-04-S1-opt.chk ${root}-05-S1-freq.chk
		    title="${root} freq analysis of stable excited state - emission"
		    echo "$(eval "echo \"$(cat ${step5})\"")" | g09 > ${root}-05-S1-freq.log

		    if [ $? -eq 0 ] ; then
	    	        #record success in logfile
			echo "${root}-05-S1-freq finished sucessfully at `date`" | tee -a $logfile 1>&2
			
			cp ${root}-05-S1-freq.chk ${root}-06-S1-solvs.chk
			title="${root} state specific solvation of emission - emission"
			echo "$(eval "echo \"$(cat ${step6})\"")" | g09 > ${root}-06-S1-solv.log

			if [ $? -eq 0 ] ; then
	    	            #record success in logfile
			    echo "${root}-06-S1-solv finished sucessfully at `date`" | tee -a $logfile 1>&2
			    
			    cp ${root}-06-S1-solvs.chk ${root}-07-emit.chk
			    title="${root} emission - emission"
			    echo "$(eval "echo \"$(cat ${step7})\"")" | g09 > ${root}-07-emit.log

			    if [ $? -eq 0 ] ; then
				echo "${root}-07-emit finished sucessfully at `date`" | tee -a $logfile 1>&2
			    else
				echo "${root}-07-emit failed at `date`" | tee -a $logfile 1>&2
			    fi
			else
			    echo "${root}-06 failed at `date`" | tee -a $logfile 1>&2
			fi
		    else
			echo "${root}-05 failed at `date`" | tee -a $logfile 1>&2
		    fi
		else
		    echo "${root}-04 failed at `date`" | tee -a $logfile 1>&2
		fi
	    else
		echo "${root}-03 failed at `date`" | tee -a $logfile 1>&2
	    fi
	else
	    echo "${root}-02 failed at `date`" | tee -a $logfile 1>&2
	fi		
    else
	echo "${root}-01 failed at `date`" | tee -a $logfile 1>&2
    fi

else
    echo "   Error: $file does not exist or is not a Gaussian input file" | tee -a $logfile 1>&2
    exit 1
fi

#!/bin/sh
# This script takes an initial .gau input file (charge, mult, and coords) and generates and runs the necessary gaussian com files for a full workup of a spin system
# This script relies on "skeleton" gaussian com files. The defaults are spinwork-[charge]-[state].com.skel in the current directory, or if not found the ones in SKEL_DIR.
## Example, say 6-31+G** is way too much for you, just do
### cp '/home/guest/scripts/spinwork-*.com.skel' (or just the specific step you want to change
## and change those files with your editor of choice
## the script checks the current working directory first before defaulting back to the ones in $SKEL_DIR

# The logic for multiplicity is kind of wonky. The current way is to add or subtract from the starting multiplicty. I assumed we're working with just electrons (s=1/2) and mult=2s+1, so adding or removing electrons increments or decrements multiplicity. By taking the difference in charge state from the current and initial systems, adding that to multiplcity yields the new high-spin multiplcity.
# For the low spin calculations, the way I've been doing them is to assume the last process ripped out a "spin important electron" (Jon-ism), so the multiplcity goes down one instead of up. Because we are still using difference in charge (which gives +1 mult), we need to add a "-2" to the equation.

# For now, this just runs the calculations, it'd be nice to have another utility that automatically does the workup, but that's for another time.
# Also! only does cationic systems, doing anionic systems shouldn't be too hard, but not a priority

#check if these variables are set explicitly, if not set them to default
if [ -z ${SKEL_DIR} ] ; then
	SKEL_DIR="/home/guest/scripts/spinwork-skel"
fi

if [ -z ${SCRIPT_DIR} ] ; then
	SCRIPT_DIR="/home/guest/scripts"
fi

#usage prompt if no arguments given
if [ ${#} -eq 0 ] ; then
    echo 'Usage: spinwork.sh gaufile [charges]'
    echo '    gaufile is the gaussian input file of the starting structure'
    echo '    charges are a list of charge states to compute (space separated)'
    exit 0
fi

#input file, and log file (uses the root of the input filename)
gaufile=$1
logfile="spinwork-${gaufile%\.*}.log"

#testing for precesence of skel files in the current directory. If none, then use the default
if [ -e "./spinwork-neutral.com.skel" ] ; then
    neutral="./spinwork-neutral.com.skel"
else
    neutral="${SKEL_DIR}/spinwork-neutral.com.skel"
fi

if [ -e "./spinwork-n-cation.com.skel" ] ; then
    cation="./spinwork-n-cation.com.skel"
else
    cation="${SKEL_DIR}/spinwork-n-cation.com.skel"
fi

if [ -e "./spinwork-n-cation-low.com.skel" ] ; then
    low="./spinwork-n-cation-low.com.skel"
else
    low="${SKEL_DIR}/spinwork-n-cation-low.com.skel"
fi

if [ -e "./spinwork-n-cation-low-restricted.com.skel" ] ; then
    lowR="./spinwork-n-cation-low-restricted.com.skel"
else
    lowR="${SKEL_DIR}/spinwork-n-cation-low-restricted.com.skel"
fi

if [ -e "./spinwork-n-cation-mix.com.skel" ] ; then
    mix="./spinwork-n-cation-mix.com.skel"
else
    mix="${SKEL_DIR}/spinwork-n-cation-mix.com.skel"
fi

#make sure our input file actually exists before starting
if [ -e $gaufile -a ${gaufile#*\.} = "gau" ] ; then
    #log start to logfile
    echo "Staring spinwork on input file: $gaufile" | tee -a $logfile 1>&2

    #the tricky part.... need to figure out the starting mulitplicity
    #find the charge/mult line in the input file, then selectively extracts the first or second number
    initmult=$(grep -E '^[0-9] +[0-9]' ${gaufile} | sed -r 's/^[0-9] +([0-9])/\1/')
    initcharge=$(grep -E '^[0-9] +[0-9]' ${gaufile} | sed -r 's/^([0-9]) +[0-9]/\1/')

    #the root of the input filename, used for all output files
    root=${gaufile%\.*}
    # our initial neutral opt, title is a variable that is expanded in the skel file
    title="${root} neutral geom opt - spinwork"
    # concatonate the skeleton com file and the input file, and evaluate to fill in variables, then pipe into gaussian
    #echo -e "$(eval "echo -e \"$(cat ${neutral} ${gaufile})\"")\n\n"
    # the above requires a cleaned .gau, below does a rough version of it for us
    echo -e "$(eval "echo -e \"$(sed -r 's/^([0-9]+) *([0-9]+)$/\1 \2/' ${gaufile} | grep -E '^[[:alnum:]]' | cat ${neutral} - )\"")\n\n"  | g09 > ${root}-neutral.log

    #test if the last command (g09) succeeded, and continue if it has
    if [ $? -eq 0 ] ; then
	#record success in logfile
	echo "${root}-neutral finished sucessfully at `date`" | tee -a $logfile 1>&2
	#generate a cubefile using my cubespin script
	CUBE_DIR=${root} ${SCRIPT_DIR}/cubespin.sh ${root}-neutral.chk

	# loop through the remaining command line arguments (the charge states to look at)
	# run calculations on all charge states passed in, using the results of the first calculation
	charges=($*)
	for charge in ${charges[@]:1} ; do
	    # 'prefix','newcharge', and 'newmult' are variables that are expanded in the skel files
	    #fornow, easiest to just make the prefix the charge
	    #todo, have prefix lookup the proper prefix of di,tri.quart,etc...
	    prefix=${charge}
	    newcharge=${charge}
	    #compute the new mulitplicity--see header for details
	    newmult=$(echo "${initmult}+(${charge}-${initcharge})" | bc -q)
	    title="${root} ${charge}+ - spinwork"
	    #copy the previous checkpoint file to use as a starting point
	    cp ${root}-neutral.chk ${root}-${prefix}+cation.chk
	    # load in and evaluate skel file for variable substitution, then pipe to gaussian to run
	    echo "$(eval "echo \"$(cat ${cation})\"")" | g09 > ${root}-${charge}+cation.log

            #test if the last command (g09) succeeded, and continue if it has
	    if [ $? -eq 0 ] ; then
		#log success to logfile
		echo "${root}-${prefix}+cation finished sucessfully at `date`" | tee -a $logfile 1>&2
		#generate a cubefile using my cubespin script
		CUBE_DIR=${root} ${SCRIPT_DIR}/cubespin.sh ${root}-${prefix}+cation.chk

		title="${root} ${charge}+ low spin - spinwork"
		newmult=$(echo "${initmult}+(${charge}-${initcharge}-2)" | bc -q)
		#multiplicity must be positive, make sure a "low spin" state is actually possible
		if [ ${newmult} -gt 0 ] ; then
		    cp ${root}-${prefix}+cation.chk ${root}-${prefix}+cation-low.chk
		    echo "$(eval "echo \"$(cat ${low})\"")" | g09 > ${root}-${charge}+cation-low.log
		    if [ $? -eq 0 ] ; then
			echo "${root}-${prefix}+cation-low finished sucessfully at `date`" | tee -a $logfile 1>&2
		    else
			echo "${root}-${prefix}+cation-low failed at `date`" | tee -a $logfile 1>&2
		    fi

		    title="${root} ${charge}+ low spin-restricted (bipolaron) - spinwork"
		    cp ${root}-${prefix}+cation.chk ${root}-${prefix}+cation-low-restricted.chk
		    echo "$(eval "echo \"$(cat ${lowR})\"")" | g09 > ${root}-${charge}+cation-low-restricted.log
		    if [ $? -eq 0 ] ; then
			echo "${root}-${prefix}+cation-low-restricted finished sucessfully at `date`" | tee -a $logfile 1>&2
		    else
			echo "${root}-${prefix}+cation-low-restricted failed at `date`" | tee -a $logfile 1>&2
		    fi

		    title="${root} ${charge}+ mixed - spinwork"
		    cp ${root}-${prefix}+cation.chk ${root}-${prefix}+cation-mix.chk
		    echo "$(eval "echo \"$(cat ${mix})\"")" | g09 > ${root}-${charge}+cation-mix.log
		    if [ $? -eq 0 ] ; then
			echo "${root}-${prefix}+cation-mix finished sucessfully at `date`" | tee -a $logfile 1>&2
		    else
			echo "${root}-${prefix}+cation-mix failed at `date`" | tee -a $logfile 1>&2
		    fi
		fi
	    else
		echo "${root}-${prefix}+cation failed at `date`" | tee -a $logfile 1>&2
	    fi
	done
    else
	echo "${root}-neutral failed at `date`" | tee -a $logfile 1>&2
    fi

else
    echo "   Error: $file does not exist or is not a Gaussian input file" | tee -a $logfile 1>&2
    exit 1
fi

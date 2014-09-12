#!/bin/sh

readonly PROGNAME=$(basename $0)
readonly ARGN=${#}
readonly INPUTFILE=${1}

if [ -z ${SKEL_DIR} ] ; then
    readonly SKEL_DIR="$(pwd)/spinwork-skel"
fi

if [ -e "./spinwork-neutral.com.skel" ] ; then
    readonly NEUTRAL_SKEL="./spinwork-neutral.com.skel"
else
    readonly NEUTRAL_SKEL="${SKEL_DIR}/spinwork-neutral.com.skel"
fi

if [ -e "./spinwork-n-cation.com.skel" ] ; then
    readonly CATION_SKEL="./spinwork-n-cation.com.skel"
else
    readonly CATION_SKEL="${SKEL_DIR}/spinwork-n-cation.com.skel"
fi

if [ -e "./spinwork-n-cation-low.com.skel" ] ; then
    readonly LOW_SKEL="./spinwork-n-cation-low.com.skel"
else
    readonly LOW_SKEL="${SKEL_DIR}/spinwork-n-cation-low.com.skel"
fi

if [ -e "./spinwork-n-cation-low-restricted.com.skel" ] ; then
    readonly LOW_RESTRICTED_SKEL="./spinwork-n-cation-low-restricted.com.skel"
else
    readonly LOW_RESTRICTED_SKEL="${SKEL_DIR}/spinwork-n-cation-low-restricted.com.skel"
fi

if [ -e "./spinwork-n-cation-mix.com.skel" ] ; then
    readonly MIX_SKEL="./spinwork-n-cation-mix.com.skel"
else
    readonly MIX_SKEL="${SKEL_DIR}/spinwork-n-cation-mix.com.skel"
fi

usage() {
    echo "Usage: $PROGNAME inputfile [charges]"
    echo "    inputfile is the gaussian .gau/.gzmat file of the starting structure"
    echo "    charges are a list of charge states to compute (space separated)"
}

main() {
    if [ $ARGN -eq 0 ] ; then
	usage
	exit 0
    fi

    if [ ! -e $INPUTFILE ] ; then
	echo "$INPUTFILE does not exist" 1>&2
	exit 1
    fi

    if [ ! ${INPUTFILE#*\.} = "gau" -a ! ${INPUTFILE#*\.} = "gzmat" ] ; then
	echo "$INPUTFILE is not a .gau/.gzmat file" 1>&2
	exit 2
    fi

    echo "Staring spinwork on input file: $INPUTFILE" 1>&2

    #Extract multiplicity and charge from input file
    local initmult=$(grep -E '^[0-9] +[0-9]' ${INPUTFILE} | sed -r 's/^[0-9] +([0-9])/\1/')
    local initcharge=$(grep -E '^[0-9] +[0-9]' ${INPUTFILE} | sed -r 's/^([0-9]) +[0-9]/\1/')

    local root=${INPUTFILE%\.*}

    local title="${root} neutral geom opt - spinwork"
    # concatonate the skeleton com file and the input file, and evaluate to fill in variables, then pipe into gaussian
    echo -e "$(eval "echo -e \"$(sed -r 's/^([0-9]+) *([0-9]+)$/\1 \2/' ${INPUTFILE} | grep -E '^[[:alnum:]]' | cat ${NEUTRAL_SKEL} - )\"")\n\n"  | g09 > ${root}-neutral.log

    if [ $? -eq 0 ] ; then
	echo "${root}-neutral finished sucessfully at `date`" 1>&2

	local charges=($*)
	for charge in ${charges[@]:1} ; do
	    prefix=${charge}
	    newcharge=${charge}

	    newmult=$(echo "${initmult}+(${charge}-${initcharge})" | bc -q)
	    title="${root} ${charge}+ - spinwork"

	    cp ${root}-neutral.chk ${root}-${prefix}+cation.chk
	    echo "$(eval "echo \"$(cat ${CATION_SKEL})\"")" | g09 > ${root}-${charge}+cation.log

	    if [ $? -eq 0 ] ; then
		echo "${root}-${prefix}+cation finished sucessfully at `date`" 1>&2

		title="${root} ${charge}+ low spin - spinwork"
		newmult=$(echo "${initmult}+(${charge}-${initcharge}-2)" | bc -q)

		if [ ${newmult} -gt 0 ] ; then
		    cp ${root}-${prefix}+cation.chk ${root}-${prefix}+cation-low.chk
		    echo "$(eval "echo \"$(cat ${LOW_SKEL})\"")" | g09 > ${root}-${charge}+cation-low.log
		    if [ $? -eq 0 ] ; then
			echo "${root}-${prefix}+cation-low finished sucessfully at `date`" 1>&2
		    else
			echo "${root}-${prefix}+cation-low failed at `date`" 1>&2
		    fi

		    title="${root} ${charge}+ low spin-restricted (bipolaron) - spinwork"
		    cp ${root}-${prefix}+cation.chk ${root}-${prefix}+cation-low-restricted.chk
		    echo "$(eval "echo \"$(cat ${LOW_RESTRICTED_SKEL})\"")" | g09 > ${root}-${charge}+cation-low-restricted.log
		    if [ $? -eq 0 ] ; then
			echo "${root}-${prefix}+cation-low-restricted finished sucessfully at `date`" 1>&2
		    else
			echo "${root}-${prefix}+cation-low-restricted failed at `date`" 1>&2
		    fi

		    title="${root} ${charge}+ mixed - spinwork"
		    cp ${root}-${prefix}+cation.chk ${root}-${prefix}+cation-mix.chk
		    echo "$(eval "echo \"$(cat ${MIX_SKEL})\"")" | g09 > ${root}-${charge}+cation-mix.log
		    if [ $? -eq 0 ] ; then
			echo "${root}-${prefix}+cation-mix finished sucessfully at `date`" 1>&2
		    else
			echo "${root}-${prefix}+cation-mix failed at `date`" 1>&2
		    fi
		fi
	    else
		echo "${root}-${prefix}+cation failed at `date`" 1>&2
	    fi
	done
    else
	echo "${root}-neutral failed at `date`" 1>&2
    fi
}

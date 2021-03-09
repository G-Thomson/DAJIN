#!/bin/bash

################################################################################
#! Initialize shell environment
################################################################################

set -u
umask 0022
export LC_ALL=C
export UNIX_STD=2003  # to make HP-UX conform to POSIX


################################################################################
#! Define the functions for printing usage and error message
################################################################################

VERSION=0.4

usage(){
cat <<- USAGE
Usage     : ./DAJIN/DAJIN.sh -i [text file] (described at "Input")

Example   : ./DAJIN/DAJIN.sh -i DAJIN/example/design.txt

Input     : Input file should be formatted as below:
            # Example
            ------
            design=DAJIN/example/example.fa
            input_dir=DAJIN/example/fastq
            control=barcode01
            genome_name=mm10
            genome_loc=UNSC
            grna=CCTGTCCAGAGTGGGAGATAGCC,CCACTGCTAGCTGTGGGTAACCC
            output_dir=DAJIN_example
            threads=10
            filter=on
            ------
            - design: a multi-FASTA file contains sequences of each genotype. ">wt" and ">target" must be included.
            - input_dir: a directory contains FASTA or FASTQ files of long-read sequencing
            - control: control barcode ID
            - genome_name: reference genome. e.g. mm10, hg38; or local FASTA file if fenome_loc is set to "local"
            - genome_loc: "UCSC" or "local" to indicate the location of the genome 
            - grna: gRNA sequence(s) including PAM. multiple gRNA sequences must be deliminated by comma.
            - output_dir (optional): output directory name. optional. Default is "DAJIN_results"
            - threads (optional; integer): Default is two-thirds of available CPU threads.
            - filter (optional; "on" or "off"): set filter to remove very minor allele (less than 3%). Default is "on"
            - approach: "conda" or "singularity" to indicate the way the pipeline works
USAGE
}

usage_and_exit(){
    usage
    exit 1
}

error_exit() {
    echo "$@" 1>&2
    exit 1
}

################################################################################
#! Parse arguments
################################################################################
[ $# -eq 0 ] && usage_and_exit

while [ $# -gt 0 ]
do
    case "$1" in
        --help | --hel | --he | --h | '--?' | -help | -hel | -he | -h | '-?')
            usage_and_exit
            ;;
        --version | --versio | --versi | --vers | --ver | --ve | --v | \
        -version | -versio | -versi | -vers | -ver | -ve | -v )
            echo "DAJIN version: $VERSION" && exit 0
            ;;
        --input | --in | --i | -i )
            if ! [ -r "$2" ]; then
                error_exit "$2: No such file"
            fi
            design=$(cat "$2" | grep "^design" | sed -e "s/ //g" -e "s/.*=//g")
            input_dir=$(cat "$2" | grep "^input_dir" | sed -e "s/ //g" -e "s/.*=//g")
            control=$(cat "$2" | grep "^control" | sed -e "s/ //g" -e "s/.*=//g")
            genome_name=$(cat "$2" | grep "^genome_name" | sed -e "s/ //g" -e "s/.*=//g")
            genome_loc=$(cat "$2" | grep "^genome_loc" | sed -e "s/ //g" -e "s/.*=//g")
            grna=$(cat "$2" | grep "^grna" | sed -e "s/ //g" -e "s/.*=//g")
            output_dir=$(cat "$2" | grep "^output_dir" | sed -e "s/ //g" -e "s/.*=//g")
            threads=$(cat "$2" | grep "^threads" | sed -e "s/ //g" -e "s/.*=//g")
            filter=$(cat "$2" | grep "^filter" | sed -e "s/ //g" -e "s/.*=//g")
            approach=$(cat "$2" | grep "^approach" | sed -e "s/ //g" -e "s/.*=//g")
            ;;
        -* )
        error_exit "Unrecognized option : $1"
            ;;
        *)
            break
            ;;
    esac
    shift
done

#===========================================================
#? Check required arguments
#===========================================================

[ -z "$design" ] && error_exit "design argument is not specified"
[ -z "$input_dir" ] && error_exit "input_dir argument is not specified"
[ -z "$control" ] && error_exit "control argument is not specified"
[ -z "$genome_name" ] && error_exit "genome_name argument is not specified"
[ -z "$genome_loc" ] && error_exit "genome_loc argument is not specified"
[ -z "$grna" ] && error_exit "grna argument is not specified"
[ -z "$approach" ] && error_exit "approach argument is not specified"

#===========================================================
#? Check fasta file
#===========================================================

[ -e "$design" ] || error_exit "$design: No such file"

[ "$(grep -c -e '>wt' -e '>target' ${design})" -ne 2 ] &&
    error_exit "$design: design must include '>target' and '>wt'. "

#===========================================================
#? Check directory
#===========================================================

[ -d "${input_dir}" ] || error_exit "$input_dir: No such directory"

fastq_num=$(find ${input_dir}/* -type f | grep -c -e ".fq" -e ".fastq")

[ "$fastq_num" -eq 0 ] && error_exit "$input_dir: No FASTQ file in directory"

#===========================================================
#? Check control
#===========================================================

if find ${input_dir}/ -type f | grep -q "${control}"; then
    :
else
    error_exit "$control: No control file in ${input_dir}"
fi

#===========================================================
#? Check genome
#===========================================================

if [ $genome_loc = UNSC ]; then
        genome_check=$(
            wget -q -O - "http://hgdownload.soe.ucsc.edu/downloads.html" |
            grep hgTracks |
            grep -c "${genome:-mm10}"
        )
elif [ $genome_loc = local ]; then
        [ -f "$genome_name" ] && genome_check=1 || genome_check=0
else
    error_exit "${genome_loc}: invalid genome_loc variable (UNSC/local)"

fi

[ "$genome_check" -eq 0 ] &&
    error_exit "$genome: No such reference genome"

#===========================================================
#? Define threads
#===========================================================

{
unset max_threads tmp_threads
max_threads=$(getconf _NPROCESSORS_ONLN)
[ -z "$max_threads" ] && max_threads=$(getconf NPROCESSORS_ONLN)
[ -z "$max_threads" ] && max_threads=$(ksh -c 'getconf NPROCESSORS_ONLN')
[ -z "$max_threads" ] && max_threads=1
tmp_threads=$(("${threads}" + 0))
}  2>/dev/null || true

if [ "${tmp_threads:-0}" -gt 1 ] && [ "${tmp_threads}" -lt "${max_threads}" ]
then
    :
else
    threads=$(echo "${max_threads}" | awk '{print int($0*2/3+0.5)}')
fi

#===========================================================
#? Make temporal directory
#===========================================================

dirs="fasta fasta_conv fasta_ont NanoSim data"
echo "${dirs}" |
    sed "s:^:.DAJIN_temp/:g" |
    sed "s: : .DAJIN_temp/:g" |
xargs mkdir -p

./DAJIN/src/format_fasta.sh "$design" "$input_dir" "$grna"

#===========================================================
#? Check approach
#===========================================================

if [ $approach = conda ]; then

./DAJIN/DAJIN_conda.sh "${control}" "${genome_name}" "${threads}" "${output_dir}" "${filter}"

elif [ $approach = singularity ]; then

./DAJIN/DAJIN_Singularity_nanosim.sh "${control}" "${threads}"

./DAJIN/DAJIN_Singularity.sh "${control}" "${genome_name}" "${threads}" "${output_dir}" "${filter}" "${approach}"

else
    error_exit "${approach}: invalid approach variable (conda/singularity)"

fi

#===========================================================
#? 
#===========================================================

cat << EOF >&2
--------------------------------------------------------------------------------
Completed!
Check ${output_dir:-DAJIN_results} directory
--------------------------------------------------------------------------------
EOF

exit 0
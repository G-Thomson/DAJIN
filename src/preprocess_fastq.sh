#!/bin/sh
# shellcheck disable=SC2002,SC2120

################################################################################
#! Initialize shell environment
################################################################################

set -u
umask 0022
export LC_ALL=C
export UNIX_STD=2003  # to make HP-UX conform to POSIX


################################################################################
#! I/O naming
################################################################################

#===========================================================
#? Auguments
#===========================================================

input_dir=${1}
threads=${2}

################################################################################
#! Format ONT reads into FASTA file
################################################################################

find "${input_dir}" -type f |
    awk -F "/" 'NF==2' |
    grep -q -e ".fq" -e ".fastq" &&
fastq_format="qcat"

find "${input_dir}" -type f |
    awk -F "/" 'NF==3' |
    grep -q -e ".fq" -e ".fastq" &&
fastq_format="guppy"


if [ _"${fastq_format}" = "_guppy" ]; then
    find "${input_dir}" -type d |
        grep barcode |
        awk '{print "cat " $0 "/*.fastq > " $0 ".fastq"}' |
        sed "s|> fastq_guppy|> .DAJIN_temp/fastq_ont|" |
        awk -v threads="${threads}" '
            {if (NR % threads == 0) sub("$", " \\&\nwait"); else sub("$", " \\&")}1
            END{print "wait"}' |
    sh 2>/dev/null

elif [ _"${fastq_format}" = "_qcat" ]; then
    cp "${input_dir}"/* .DAJIN_temp/fastq_ont/

else
    printf "The format of FASTQ files are incorrect.\nRead https://github.com/akikuno/DAJIN/blob/master/docs/INPUT_DIR.md\n"
    exit 1
fi

exit 0

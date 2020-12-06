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
#! Input/Output
################################################################################

input_dir="$1"
threads="$2"

################################################################################
#! Save FASTQ to .DAJIN_temp/fastq_ont
################################################################################

./DAJIN/src/preprocess_fastq.sh "$input_dir" "$threads"

################################################################################
#! Generate SAM files to '.DAJIN_temp/sam'
################################################################################

find .DAJIN_temp/fastq_ont/ -type f |
while read -r input; do
    ./DAJIN/src/classif_mapping.sh "${input}" "${threads}"
done

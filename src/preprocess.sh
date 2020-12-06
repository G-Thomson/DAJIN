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

# input: FASTQ, output: FASTA
./DAJIN/src/preprocess_fastq.sh "$input_dir" "$threads"

# input: FASTQ, output: FASTA

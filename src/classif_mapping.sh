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
#! Name Input/Output
################################################################################

#===========================================================
#? Input auguments
#===========================================================

query=${1}
threads=${2}

################################################################################
#! Generate SAM files
################################################################################

find .DAJIN_temp/fasta -type f |
grep -v -e fasta.fa -e fasta_revcomp.fa |
while read -r ref; do
    allele=$(echo "${ref##.*/}" | sed "s/.fa//")
    barcode=$(echo "${query##.*/}" | sed "s/.fa//")
    minimap2 -t "${threads}" -ax splice "${ref}" "${query}" --cs=long 2>/dev/null |
    cat > ".DAJIN_temp/sam/${barcode}_${allele}.sam"
done

exit 0
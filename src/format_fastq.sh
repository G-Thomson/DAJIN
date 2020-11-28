#!/bin/sh

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

find "${input_dir}"/* -type f |
    awk -F "/" 'NF==2' |
    grep -q -e ".fq" -e ".fastq" &&
fastq_format="qcat"

find "${input_dir}"/* -type f |
    awk -F "/" 'NF==3' |
    grep -q -e ".fq" -e ".fastq" &&
fastq_format="guppy"

fastq_to_fasta()(
    awk '(4+NR) % 4 == 1 || (4+NR) % 4 == 2' |
    sed 's/^@/>/'
)

if [ _"${fastq_format}" = "_guppy" ]; then
    find "${input_dir}" -type d |
        grep barcode |
        awk '{print "cat " $0 "/*.fastq | fastq_to_fasta > " $0 ".fa &"}' |
        sed "s|> fastq_guppy|> .DAJIN_temp/fasta_ont|" |
        awk -v th="${threads:-1}" '
            {if (NR % th == 0) gsub("&", "&\nwait", $0)}1
            END{print "wait"}' |
    cat > .DAJIN_temp/tmp_fastq_to_fasta.sh
    . .DAJIN_temp/tmp_fastq_to_fasta.sh 2>/dev/null

elif [ _"${fastq_format}" = "_qcat" ]; then
    find "${input_dir}" -type f |
        grep barcode |
        awk '{print "cat " $0 "| fastq_to_fasta > " $0".fa &"}' |
        sed "s|> fastq_qcat|> .DAJIN_temp/fasta_ont|" |
        sed "s/fasta.fa/fa/g" |
        awk -v th="${threads:-1}" '
            {if (NR % th == 0) gsub("&", "&\nwait", $0)}1
            END{print "wait"}' |
    cat > .DAJIN_temp/tmp_fastq_to_fasta.sh
    . .DAJIN_temp/tmp_fastq_to_fasta.sh 2>/dev/null

else
    printf "The format of FASTQ files are incorrect.\nRead https://github.com/akikuno/DAJIN/blob/master/docs/INPUT_DIR.md\n"
    exit 1
fi

rm .DAJIN_temp/tmp_fastq_to_fasta.sh 2>/dev/null

exit 0

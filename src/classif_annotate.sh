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

barcode=${1}

#===========================================================
#? Output
#===========================================================
mkdir -p .DAJIN_temp/classif

output=.DAJIN_temp/classif/"${barcode}"

################################################################################
#! Concatenate score files
################################################################################

find .DAJIN_temp/score -type f |
grep "${barcode}" |
xargs cat |
awk -v OFS=","  '{
    sub("\*","abnormal", $2)
    if(score[$1]=="") {allele[$1]=$2; score[$1]=$3}
    if(score[$1]>$3) {allele[$1]=$2; score[$1]=$3}}
    END{for(key in score) print key, score[key], allele[key]}' |
cat > "$output"

possible_alleles=$(cat "$output" | cut -d "," -f 3 | sort -u)

cat "$output" |
awk -F "," -v output="${output}" -v alleles="${possible_alleles}" '{
    split(alleles, a, "\n")
    for(i in a) {
        if($3 == a[i]) print $0 > output"_"a[i]".csv"
    }
}'

rm "${output}"


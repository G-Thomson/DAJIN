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

input_sam=${1}

# allele=$(echo ${input_sam##*_} | sed "s/.sam//")
# barcode=$(echo ${input_sam##*/} | cut -d "_" -f 1)

#===========================================================
#? Output
#===========================================================

mkdir -p .DAJIN_temp/score
output_score=$(echo "${input_sam%%.sam}" | sed "s|sam|score|")
tmp_prefix=$(echo "${input_sam%%.sam}" | sed "s|sam/|score/tmp_|")

################################################################################
#! Functions
################################################################################

count_mutation_in_cstag()(
    if [ -p /dev/stdin ] && [ "$*" = "" ]; then
        cat -
    elif [ -f "$*" ]; then
        cat "$*"
    else
        echo "$*"
    fi |
    awk '{
    sum=0
    sub("cs:Z:", "")
    gsub(/[-=+~]/, "")
    gsub(/\*[acgt][acgt]/, " 1 ")
    gsub(/[acgt]/, " 1 ")
    gsub(/[ACGT]/, " 0 ")
    for(i=1;i<=NF;i++) sum+=$i
    if(sum == 0) sum=1 # for logarithmic transformation
    print sum }'
)

mapped_length_in_cstag()(
    if [ -p /dev/stdin ] && [ "$*" = "" ]; then
        cat -
    elif [ -f "$*" ]; then
        cat "$*"
    else
        echo "$*"
    fi |
    awk '{sum=0
    sub("cs:Z:", "")
    gsub(/[-=+]/, "")
    gsub(/~[acgt][acgt][0-9]*[acgt][acgt]/, " 0 ")
    gsub(/\*[acgt][acgt]/, " 0 ")
    gsub(/[acgt]/, " 0 ")
    gsub(/[ACGT]/, " 1 ")
    for(i=1;i<=NF;i++) sum+=$i
    if(sum == 0) sum=1 # for division 
    print sum }'
)

################################################################################
#! Scoring
################################################################################

grep -v "^@" "${input_sam}" > "${tmp_prefix}.sam"

cat "${tmp_prefix}.sam" |
    awk '{print $(NF-1)}' |
    count_mutation_in_cstag |
cat > "${tmp_prefix}_score"

cat "${tmp_prefix}.sam" |
    awk '{print $(NF-1)}' |
    mapped_length_in_cstag |
cat > "${tmp_prefix}_length"

cat "${tmp_prefix}.sam" |
    cut -f 1,3 |
    paste "${tmp_prefix}_score" "${tmp_prefix}_length" - |
    awk '{sum[$3" "$4] += ($1/$2)} END {for(key in sum) print key, log(sum[key])}' |
cat > "${output_score}"

rm "${tmp_prefix}_score" "${tmp_prefix}_length"

exit 0
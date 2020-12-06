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
#! Count mutation nucleotides
################################################################################

find .DAJIN_temp/sam/ -type f |
awk '{print "DAJIN/src/classif_scoring.sh", $0, "&"}' |
awk -v th="${threads:-1}" '
    NR%th == 0 {gsub("&","&\nwait")}1
    END{print "wait"}' |
sh - 2>/dev/null

rm .DAJIN_temp/score/tmp_*

################################################################################
#! Annotate alleles
################################################################################

find .DAJIN_temp/score/ -type f |
sed "s|^.*/||" |
cut -d "_" -f 1 |
sort -u |
awk '{print "DAJIN/src/classif_annotate.sh", $0, "&"}' |
awk -v th="${threads:-1}" '
    NR%th == 0 {sub("&","&\nwait")}1
    END{print "wait"}' |
sh - 2>/dev/null

################################################################################
#! Anomaly detection
################################################################################

find .DAJIN_temp/classif/ -type f |
grep "$control" |
grep "wt" |
xargs -I @ \
    Rscript DAJIN/src/classif_anomaly_control_trim.R @ "${threads}"

python DAJIN/src/classif_anomaly_control_lof.py \
    ".DAJIN_temp/classif/tmp_control_score.csv" "${threads}"

find .DAJIN_temp/classif/ -type f |
grep "csv" |
grep -v -e "$control" -e "tmp_" |
xargs -I @ python DAJIN/src/classif_anomaly_sample_lof.py @

find .DAJIN_temp/classif/ -type f |
    grep lof$ |
    sed "s|^.*/||" |
    cut -d "_" -f 1 |
    sort -u |
while read -r barcode; do
cat .DAJIN_temp/classif/"${barcode}"*lof |
    cut -f 1,3 |
    sort |
cat > ".DAJIN_temp/classif/${barcode}.txt"
done

rm .DAJIN_temp/classif/*.sav
rm .DAJIN_temp/classif/*.csv
rm .DAJIN_temp/classif/*_lof
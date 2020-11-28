#!/bin/sh

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

################################################################################
#! Concatenate score files
################################################################################

find .DAJIN_temp/score -type f |
grep "${barcode}" |
xargs cat |
awk -v OFS=","  '{
    if(score[$1]=="") {allele[$1]=$2; score[$1]=$3}
    if(score[$1]>$3) {allele[$1]=$2; score[$1]=$3}}
    END{for(key in score) print key, score[key], allele[key]}' |
cat > tmp


cat tmp | cut -d "," -f 3 | sort | uniq -c

# rm .DAJIN_temp/score/tmp_*

# head tmp_result
# cat tmp_result | awk -F "," '$2 == 0' | wc -l
# cat "${tmp_prefix}.sam" | cut -f 2 | sort | uniq -c

# library(tidyverse)
# df <- read_csv("tmp", col_name = c("id","score","allele"), col_type = c())
# df <- df %>% mutate(score = if_else(score == 0, 0.00001, score))
# df <- df %>% mutate(log = log(score))
# df$score %>% summary

# df_trim <- df %>% filter(log > quantile(df$log, 0.025) & log < quantile(df$log, 0.995))
# ggplot(df_trim, aes(sample = log)) + stat_qq() + stat_qq_line()
# ggplot(df_trim, aes(y = log)) + geom_histogram() + coord_flip()

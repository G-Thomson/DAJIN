#!/bin/sh

count_mutation_in_cstag()(
    if [ -p /dev/stdin ] && [ "$*" = "" ]; then
        cat -
    elif [ -f "$*" ]; then
        cat "$*"
    else
        echo "$*"
    fi |
    awk '{sum=0
    sub("cs:Z:", "")
    gsub(/[-=+~]/, "")
    gsub(/\*[acgt][acgt]/, " 1 ")
    gsub(/[acgt]/, " 1 ")
    gsub(/[ACGT]/, " 0 ")
    for(i=1;i<=NF;i++) sum+=$i
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
    if(sum == 0) sum=1
    print sum }'
)


ref_fa=.DAJIN_temp/fasta/wt.fa
threads=14

true > tmp_score_output
que_fa=.DAJIN_temp/fasta_ont/barcode32.fa

find .DAJIN_temp/fasta -type f |
grep -v -e fasta.fa -e fasta_revcomp.fa |
while read -r ref_fa; do
    allele=$(echo ${ref_fa##.*/} | sed "s/.fa//g")

    minimap2 -t ${threads} -ax splice "${ref_fa}" "${que_fa}" --cs=long 2>/dev/null |
    grep -v "^@" > tmp.sam

    cat tmp.sam |
        awk '{print $(NF-1)}' |
        count_mutation_in_cstag |
    cat > tmp_score

    cat tmp.sam |
        awk '{print $(NF-1)}' |
        mapped_length_in_cstag |
    cat > tmp_length

    cat tmp.sam |
        cut -f 1 |
        paste - tmp_score tmp_length |
        awk '{sum[$1] += ($2/$3)} END {for(key in sum) print key, sum[key]}' |
        awk -v allele="$allele" '{print $0, allele}' |
    cat >> tmp_score_output
done

cat tmp_score_output |
awk -v OFS=","  '{
    if(score[$1]=="") {score[$1]=$2; allele[$1]=$3}
    if(score[$1]>$2) {score[$1]=$2; allele[$1]=$3}}
    END{for(key in score) print key, score[key], allele[key]}' |
cat > tmp_result

cat tmp_result | cut -d "," -f 3 | sort | uniq -c
head tmp_result
cat tmp_result | awk -F "," '$2 == 0' | wc -l
cat tmp.sam | cut -f 2 | sort | uniq -c

library(tidyverse)
df <- read_csv("tmp_result", col_name = c("id","score","allele"), col_type = c())
df <- df %>% mutate(score = if_else(score == 0, 10^-1000, score))
df <- df %>% mutate(log = log(score))
df$score %>% summary

df_trim <- df %>% filter(log > quantile(df$log, 0.025) & log < quantile(df$log, 0.995))
ggplot(df_trim, aes(sample = log)) + stat_qq() + stat_qq_line()
ggplot(df_trim, aes(y = log)) + geom_histogram() + coord_flip()


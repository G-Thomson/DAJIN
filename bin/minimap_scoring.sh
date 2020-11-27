#!/bin/sh

# TA-gctTTGAG*ca=A*tc=TC*ac=GGG
# 001110000101001000の総和

# 変異塩基（欠失挿入置換）は1を加算する.
# "=AAAAAA" -> すべてマッチしているので"0"
# "=AAA+aAA" -> 1塩基挿入なので"1"
# "=AAA-aAA" -> 1塩基欠失なので"1"
# "=AAA*acAA" -> 1塩基置換なので"1"
# "=AAA+aa-g*acAA" -> 2塩基挿入, 1塩基欠失, 1塩基置換なので"2+1+1=4"

echo "=AAAAAA" |
awk -F "" '{
    gsub(/[-=+]/, "")
    gsub(/[ACGT]/, "0")
    for(i=1;i<=NF;i++) sum+=$i
    print sum
}'



echo "TA-gctTTGAG*ca=A*tc=TC*ac=GGG" |


# ref_fa=.DAJIN_temp/fasta/wt.fa
# que_fa=.DAJIN_temp/fasta_ont/barcode21.fa

# minimap2 -t 14 -ax splice "${ref_fa}" "${que_fa}" --cs=long 2>/dev/null > tmp.sam
# wc -l tmp.sam
# cat tmp.sam | awk '$3 == "wt"' |
# awk '{cs=$(NF-1)
# gsub()
# }'
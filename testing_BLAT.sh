#!/bin/bash

#===========================================================
#? Arguments
#===========================================================

genome="${1}"
threads="${2}"

echo ${genome}
# ################################################################################
# #! Define the functions for printing usage and error message
# ################################################################################

# error_exit() {
#     ${2+:} false && echo "${0##*/}: $2" 1>&2
#     exit $1
# }

# # #===============================================================================
# # #? Temporal
# # #===============================================================================

# # rm -rf ./flanks

# flanks=./DAJIN_temp/flanks
# mkdir -p "${flanks}"

# ref_fa=.DAJIN_temp/data/ref.fa

# # ################################################################################
# # #! Obtain Genome coodinates from local genome
# # ################################################################################

# # #===============================================================================
# # #? Left flank
# # #===============================================================================
# lf=">left_flank"
# echo $lf >> ./DAJIN_temp/flanks/left_flank.fa

# cat ./wt.fa | 
#     sed 1d | 
#     awk '{seq=substr($0, 1, 100); print seq}' |
#     cat >> ./DAJIN_temp/flanks/left_flank.fa 

# blat -noHead -stepSize=5 -repMatch=2253 -minScore=20 -minIdentity=0 ./genome/mm10.2bit ./DAJIN_temp/flanks/left_flank.fa ./DAJIN_temp/flanks/LF_output.psl

# cat ./DAJIN_temp/flanks/LF_output.psl | 
#     awk '$1==100 && $18==1' > ./DAJIN_temp/flanks/LF_select.psl

# pslToBed ./DAJIN_temp/flanks/LF_select.psl ./DAJIN_temp/flanks/LF_select.bed

# # #===============================================================================
# # #? Right flank
# # #===============================================================================
# rf=">right_flank"
# echo $rf >> ./DAJIN_temp/flanks/right_flank.fa

# cat ./wt.fa | 
#     sed 1d |
#     awk '{seq=substr($0, length($0)-99, length($0)); print seq}' |
#     cat >> ./DAJIN_temp/flanks/right_flank.fa 

# blat -noHead -stepSize=5 -repMatch=2253 -minScore=20 -minIdentity=0 ./genome/mm10.2bit ./DAJIN_temp/flanks/right_flank.fa ./DAJIN_temp/flanks/RF_output.psl

# cat ./DAJIN_temp/flanks/RF_output.psl | 
#     awk '$1==100 && $18==1' > ./DAJIN_temp/flanks/RF_select.psl

# pslToBed ./DAJIN_temp/flanks/RF_select.psl ./DAJIN_temp/flanks/RF_select.bed

# # #===============================================================================
# # #? Combine and assign genome location to variables
# # #===============================================================================

# cat ./DAJIN_temp/flanks/LF_select.bed ./DAJIN_temp/flanks/RF_select.bed > tmp_genome_location.bed

# tmp_genome_location=./DAJIN_temp/flanks/tmp_genome_location.bed

# [ $(cat "${tmp_genome_location}" | wc -l) -ne 2 ] && 
# error_exit 1 '
# # No matched sequence found in reference genome:
# # Check FASTA sequence and reference genome.'

# chromosome=$(cat "${tmp_genome_location}"| head -n 1| cut -f 1)
# start=$(cat "${tmp_genome_location}"| sort -k 2,3n | head -n 1 | cut -f 2)
# end=$(cat "${tmp_genome_location}" | sort -k 2,3nr | head -n 1 | cut -f 3)

# ################################################################################
# #! Obtain Reference fasta file from 2Bit file
# ################################################################################

# twoBitToFa -seq=$chromosome -start=$start -end=$end ./genome/mm10.2bit ref_fa

# [ $(cat "${ref_fa}" | wc -l) -eq 0 ] &&
# error_exit 1 'Invalid reference genome.'

# ################################################################################
# #! Mapping for IGV
# ################################################################################

# #===============================================================================
# #? Rerefence Chromosome length
# #===============================================================================

# chrom_len=$(awk -v chr=$chromosome '{if($1==chr) print $2}' ./genome/genome.chrom.sizes)

# [ $(echo ${chrom_len} | wc -l) -eq 0 ] &&
# error_exit 1 'Invalid reference genome.'

# #===============================================================================
# #? Mapping all reads
# #===============================================================================

# reference="${ref_fa}"
# for input in .DAJIN_temp/fasta_ont/*; do
#     output=$(echo "${input}" |
#         sed -e "s#.*/#${bam_all}/#g" \
#             -e "s/\.f.*$/.bam/g")
#     # echo "${output} is now generating..."
#     ####
#     minimap2 -t ${threads:-1} -ax map-ont --cs=long ${reference} ${input} 2>/dev/null |
#         awk -v chrom="${chromosome}" -v chrom_len="${chrom_len}" -v start="${start}" \
#         'BEGIN{OFS="\t"}
#         $1~/@SQ/ {$0="@SQ\tSN:"chrom"\tLN:"chrom_len; print}
#         $1!~/^@/ {$3=chrom; $4=start+$4-1; print}' |
#         samtools sort -@ ${threads:-1} - 2>/dev/null |
#     cat > "${output}"
#     samtools index -@ ${threads:-1} "${output}"
# done

# rm ${tmp_genome_location}

# exit 0
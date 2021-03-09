#!/bin/bash

#===========================================================
#? Arguments
#===========================================================

control="${1}"
genome_name="${2}"
threads="${3}"
output_dir="${4}"
filter="${5}"
approach="${6}"

################################################################################
#! MIDS conversion
################################################################################

cat << EOF >&2
--------------------------------------------------------------------------------
Preprocessing
--------------------------------------------------------------------------------
EOF

# #===========================================================
# #? Get mutation loci
# #===========================================================

minimap2 -ax splice \
    ".DAJIN_temp/fasta_conv/wt.fa" ".DAJIN_temp/fasta_conv/target.fa" \
    --cs 2>/dev/null |
    awk '{for(i=1; i<=NF;i++) if($i ~ /cs:Z/) print $i}' |
    sed -e "s/cs:Z:://g" -e "s/:/ /g" -e "s/~/ /g" |
    tr -d "\~\*\-\+atgc" |
    awk '{$NF=0; for(i=1;i<=NF;i++) sum+=$i} END{print $1,sum}' |
cat > .DAJIN_temp/data/mutation_points

#===========================================================
#? MIDS conversion
#===========================================================

find .DAJIN_temp/fasta_ont -type f |
    sort |
    awk '{print "./DAJIN/src/mids_classification.sh", $0, "wt", "&"}' |
    awk -v th=${threads:-1} '{
        if (NR%th==0) gsub("&","&\nwait",$0)
        print}
        END{print "wait"}' |
sh - 2>/dev/null

################################################################################
#! Prediction
################################################################################

cat << EOF >&2
--------------------------------------------------------------------------------
Predict allele types
--------------------------------------------------------------------------------
EOF

./DAJIN/src/ml_prediction.sh "${control}" "${threads}" \
> .DAJIN_temp/data/DAJIN_MIDS_prediction_result.txt ||
exit 1


################################################################################
#! Clustering
################################################################################

cat << EOF >&2
--------------------------------------------------------------------------------
Clustering alleles
--------------------------------------------------------------------------------
EOF

rm -rf .DAJIN_temp/clustering 2>/dev/null || true
mkdir -p .DAJIN_temp/clustering/temp

#===========================================================
#? Prepare control's score to define sequencing error
#===========================================================

./DAJIN/src/clustering_control_scoring.sh "${control}" "${threads}"

#===========================================================
#? Clustering
#===========================================================

cat .DAJIN_temp/data/DAJIN_MIDS_prediction_result.txt |
    cut -f 2,3 |
    sort -u |
    awk -v ctrl="$control" '$1 $2 != ctrl "wt"' |
    awk -v th="${threads:-1}" '{print "./DAJIN/src/clustering.sh", $1, $2, th}' |
sh -

cat .DAJIN_temp/data/DAJIN_MIDS_prediction_result.txt |
    awk -v ctrl="$control" '$2 $3 == ctrl "wt" {print $1"\t"1}' |
cat > ".DAJIN_temp/clustering/temp/hdbscan_${control}_wt"
cat ".DAJIN_temp/clustering/temp/hdbscan_${control}_wt" > .DAJIN_temp/clustering/temp/query_seq_${control}_wt
true > ".DAJIN_temp/clustering/temp/possible_true_mut_${control}_wt"

#===========================================================
#? Allele percentage
#===========================================================

rm -rf ".DAJIN_temp/clustering/allele_per/" 2>/dev/null
mkdir -p ".DAJIN_temp/clustering/allele_per/"

cat .DAJIN_temp/data/DAJIN_MIDS_prediction_result.txt |
    cut -f 2 |
    sort -u |
    awk -v filter="${filter:-on}" \
    '{print "./DAJIN/src/clustering_allele_percentage.sh", $1, filter, "&"}' |
    awk -v th="${threads:-1}" '{
        if (NR%th==0) gsub("&","&\nwait",$0)}1
        END{print "wait"}' |
sh -

################################################################################
#! Get consensus sequence in each cluster
################################################################################

cat << EOF >&2
--------------------------------------------------------------------------------
Report consensus sequence
--------------------------------------------------------------------------------
EOF

#===========================================================
#? Setting directory
#===========================================================

rm -rf .DAJIN_temp/consensus 2>/dev/null || true
mkdir -p .DAJIN_temp/consensus/temp .DAJIN_temp/consensus/sam

#===========================================================
#? Generate temporal SAM files
#===========================================================

cat .DAJIN_temp/clustering/allele_per/label* |
    cut -d " " -f 1,2 |
    sort -u |
    grep -v abnormal |  #TODO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
while read -r input; do
    barcode="${input%% *}"
    mapping_alleletype="$(echo "${input##* }" | sed "s/abnormal/wt/g" | sed "s/normal/wt/g")"

    cat .DAJIN_temp/clustering/allele_per/readid_cl_mids_"${barcode}"_"${mapping_alleletype}" |
        awk '{print ">"$1}' |
        sort |
    cat > .DAJIN_temp/consensus/tmp_id

    cat .DAJIN_temp/fasta_ont/"${barcode}".fa |
        awk '{print $1}' |
        tr "\n" " " |
        awk '{gsub(">", "\n>")}1' |
        grep -v "^$" |
        sort |
        join - .DAJIN_temp/consensus/tmp_id |
        awk '{gsub(" ", "\n")}1' |
        grep -v "^$" |
        minimap2 -ax map-ont -t "${threads}" \
            ".DAJIN_temp/fasta/${mapping_alleletype}.fa" - \
            --cs=long 2>/dev/null |
        sort |
    cat > .DAJIN_temp/consensus/sam/"${barcode}"_"${mapping_alleletype}".sam
    rm .DAJIN_temp/consensus/tmp_id
done

#===========================================================
#? Execute consensus.sh
#===========================================================

cat .DAJIN_temp/clustering/allele_per/label* |
    awk '{nr[$1]++; print $0, nr[$1]}' |
    grep -v abnormal |  #TODO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    awk '{print "./DAJIN/src/consensus.sh", $0, "&"}' |
    awk -v th="${threads:-1}" '{
        if (NR%th==0) gsub("&","&\nwait",$0)}1
        END{print "wait"}' |
sh -

################################################################################
#! Summarize to Details.csv and Details.pdf
################################################################################

./DAJIN/src/details.sh

################################################################################
#! Mapping by minimap2 for IGV visualization
################################################################################

cat << EOF >&2
--------------------------------------------------------------------------------
Generate BAM files
--------------------------------------------------------------------------------
EOF

./DAJIN/src/generate_bam.sh "${genome_name}" "${threads}" "${approach}"

################################################################################
#! Move output files
################################################################################

rm -rf "${output_dir:=DAJIN_results}" 2>/dev/null || true
mkdir -p "${output_dir:-DAJIN_results}"/BAM
mkdir -p "${output_dir:-DAJIN_results}"/Consensus

#===========================================================
#? BAM
#===========================================================

rm -rf .DAJIN_temp/bam/temp 2>/dev/null || true
cp -r .DAJIN_temp/bam/* "${output_dir:-DAJIN_results}"/BAM/ 2>/dev/null

#===========================================================
#? Consensus
#===========================================================

(   find .DAJIN_temp/consensus/* -type d |
    grep -v -e "consensus/temp" -e "sam" |
    xargs -I @ cp -f -r @ "${output_dir:-DAJIN_results}"/Consensus/
) 2>/dev/null || true

#===========================================================
#? Details
#===========================================================

cp .DAJIN_temp/details/* "${output_dir:-DAJIN_results}"/

################################################################################
#! Finish call
################################################################################

[ -z "${TEST}" ] && rm -rf .DAJIN_temp/
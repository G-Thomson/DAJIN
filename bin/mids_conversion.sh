#!/bin/sh

mids_conversion()(
    if [ -p /dev/stdin ] && [ "$*" = "" ]; then
        cat -
    elif [ -f "$*" ]; then
        cat "$*"
    else
        echo "$*"
    fi |
    # long deletion
    sed "s/~[acgt][acgt]\([0-9][0-9]*\)[acgt][acgt]/ ~\1 /g" |
    awk '{for(i=5;i<=NF;i++){
        if($i ~ /\~/){
            sub("~","",$i)
            len=int($i)
            for(j=1; j<=len; j++) str = "D" str
            $i=str
            str=""
        }
    }}1' 2>/dev/null |
    awk '{printf $1" "$2" "$3" "$4" "
        for(i=5;i<=NF;i++) printf $i
        printf "\n"}' |
    # insertion/point mutation/inversion
    awk '{id=$1; strand=$3; loc=$4; $0=$5;
    sub("cs:Z:","",$0)
    sub("D"," D",$0)
    gsub(/[ACGT]/, "M", $0)
    gsub(/\*[acgt][acgt]/, " S", $0)
    gsub("=", " ", $0)
    gsub("\+", " +", $0)
    gsub("\-", " -", $0)
    for(i=1; i<=NF; i++){
        if($i ~ /^\+/){
            len=length($i)-1
            if(len>=10 && len<=35) len=sprintf("%c", len+87)
            else if(len>=36) len="z"
            $i=" "
            $(i+1)=len substr($(i+1),2) }
        else if($i ~ /^\-/){
            len=length($i)-1
            for(len_=1; len_ <= len; len_++){
                str= "D" str
            }
            $i=str
            str=""}
        }
    gsub(" ", "", $0)
    print id, loc, $0, strand}' 2>/dev/null |
sort -t " "
)
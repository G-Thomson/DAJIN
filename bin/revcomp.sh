#!/bin/sh

revcomp()(
    if [ -p /dev/stdin ] && [ "$*" = "" ]; then
        cat -
    elif [ -f "$*" ]; then
        cat "$*"
    else
        echo "$*"
    fi |
    # Complement
    awk 'BEGIN{FS=""}
        $1 ~ /^[>@]/ {print; next}{
        nuc=""; seq=""
        for(i=1; i<=NF; i++){
            $i=toupper($i)
            if($i=="A") nuc="T"
            else if($i=="C") nuc="G"
            else if($i=="G") nuc="C"
            else if($i=="T") nuc="A"
            else nuc=$i
            seq=seq""nuc
            }
        print seq}' |
    # Reverse
    awk 'BEGIN{FS=""}
        $1 ~ /^[>@]/ {print; next}{
            seq=""
            for(i=NF; i>0; i--) seq=seq""$i
        print seq}'
)

#!/bin/sh

fastq_to_fasta()(
    if [ -p /dev/stdin ] && [ "$*" = "" ]; then
        cat -
    elif [ -f "$*" ]; then
        cat "$*"
    else
        echo "$*"
    fi |
    awk '(4+NR) % 4 == 1 || (4+NR) % 4 == 2' |
    sed 's/^@/>/'
)

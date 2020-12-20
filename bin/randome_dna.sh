#!/bin/sh

random_dna()(
    cat /dev/urandom |
    od -t u -N $(("$1"*10)) |
    tr -d "\n 056789" |
    tr "1234" "ACGT" |
    awk -v len="$1" '{print substr($0, 1, len)}'
)
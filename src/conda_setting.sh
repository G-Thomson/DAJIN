#!/bin/bash

set +u

error_exit() {
    echo "$@" 1>&2
    exit 1
}

conda --version >/dev/null 2>&1 || error_exit 'Command "conda" not found'

#===========================================================
#? DAJIN
#===========================================================

if [ "$(conda info -e | cut -d " " -f 1 | grep -c DAJIN$)" -eq 0 ]; then
    echo Create "DAJIN" environment... >&2
    conda update -y conda >/dev/null 2>&1
    conda create -y -n DAJIN python=3.7 \
        numpy pandas scikit-learn joblib hdbscan \
        wget emboss samtools minimap2 \
        r-essentials r-base r-reticulate r-vroom r-furrr >/dev/null 2>&1
fi

#===========================================================
#? Required software
#===========================================================

conda activate DAJIN

gzip --version >/dev/null 2>&1 || error_exit 'Command "gzip" installation has failed'
wget --version >/dev/null 2>&1 || error_exit 'Command "wget" installation has failed'
stretcher --version >/dev/null 2>&1 || error_exit 'Command "stretcher" installation has failed'
python --version >/dev/null 2>&1 || error_exit 'Command "python" installation has failed'
R --version >/dev/null 2>&1 || error_exit 'Command "Rscript" installation has failed'
minimap2 --version >/dev/null 2>&1 || error_exit 'Command "minimap2" installation has failed'

if samtools --version 2>&1 | grep -q libcrypto; then
    CONDA_ENV=$(conda info -e | awk '$2=="*"{print $NF}')
    (cd "${CONDA_ENV}"/lib/ && ln -s libcrypto.so.1.1 libcrypto.so.1.0.0)
fi
samtools --version >/dev/null 2>&1 || error_exit 'Command "samtools" installation has failed'

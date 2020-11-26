# Directory tree in `input_dir`

The output directory trees are different from `Guppy` and `qcat`.  
DAJIN accepts the both directory as an `input_dir` argument, but you must follow one of them.  

> NOTE: We recommend you to use `Guppy` because [qcat is deprecated](https://github.com/nanoporetech/qcat)

## Guppy

```
fastq/
├── barcode01
│   ├── fastq_runid_d0ed1b19a43ebe404d12c26165fbfc29fca49e07_0_0.fastq
│   ├── fastq_runid_d0ed1b19a43ebe404d12c26165fbfc29fca49e07_100_0.fastq
├── barcode02
│   ├── fastq_runid_d0ed1b19a43ebe404d12c26165fbfc29fca49e07_0_0.fastq
│   ├── fastq_runid_d0ed1b19a43ebe404d12c26165fbfc29fca49e07_100_0.fastq
```

## qcat

```
fastq/
├── barcode01.fasta
├── barcode02.fasta
```

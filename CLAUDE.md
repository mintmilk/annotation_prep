# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Prepare genome annotation files for chicken (GRCg7b) RNA-seq analysis:
1. **Enhancer BED** — LiftOver enhancer annotations from galGal6 → GRCg7b, then convert RefSeq chr names to Ensembl names
2. **TE annotation** — Build a TElocal-compatible TE index from RepeatMasker output for GRCg7b

## Project Structure

```
annotation_prep/
├── 01_enhancer/          # Enhancer BED liftover pipeline
│   ├── download.sh       # Figshare data + chain file + assembly report
│   ├── liftover.sh       # liftOver + RefSeq→Ensembl chr renaming
│   └── output/           # enhancer_annotation_grcg7b.bed
├── 02_te_annotation/     # TE index build pipeline
│   ├── download.sh       # RepeatMasker .out + makeTEgtf.pl
│   ├── build_te_gtf.sh   # .out → GTF via makeTEgtf.pl + chr renaming + scaffold removal
│   ├── build_te_index.sh # TElocal --build → .locInd.gz
│   └── output/           # GRCg7b_rmsk_TE.gtf, GRCg7b_rmsk_TE.locInd.gz
└── shared/               # Files used by both pipelines
    ├── assembly_report.txt
    └── refseq_to_ensembl.tsv
```

## Key Data Sources

- **Enhancer data**: Pan et al. 2023 (Science Advances), Figshare: https://figshare.com/articles/dataset/Chicken_FAANG/20032103
- **LiftOver chain** (galGal6 → GRCg7b): `galGal6ToGCF_016699485.2.over.chain.gz` from UCSC
- **RepeatMasker output**: `GCF_016699485.2.repeatMasker.out.gz` from UCSC GenArk
- **makeTEgtf.pl**: from Hammell lab (TEtranscripts project)
- **Assembly report** (RefSeq↔Ensembl chr mapping): `GCF_016699485.2_assembly_report.txt` from UCSC

## Chromosome Name Convention

Target genome is GRCg7b with **Ensembl-style** chr names: `1, 2, ..., 33, W, Z, MT` (no "chr" prefix).

The liftOver chain and RepeatMasker output use **RefSeq accessions** (e.g. `NC_052532.1`). Every pipeline must include a RefSeq→Ensembl renaming step using the mapping in `shared/refseq_to_ensembl.tsv`. Scaffolds/unplaced contigs should be removed from final outputs.

## Common Commands

```bash
# Run full enhancer pipeline
cd 01_enhancer && bash download.sh && bash liftover.sh

# Run full TE annotation pipeline
cd 02_te_annotation && bash download.sh && bash build_te_gtf.sh && bash build_te_index.sh
```

## Deployment

Scripts are built locally then pushed to HPC for execution:
- **HPC host**: `HPC2-via-dell-frp`
- **Remote path**: `/work/home/zhgroup02/zzy/gtex/00_annotation_prep`
- **Push**: `rsync -avz --exclude='*.gz' ./ HPC2-via-dell-frp:/work/home/zhgroup02/zzy/gtex/00_annotation_prep/`

### HPC Environment

```bash
# Activate base bioinformatics environment (has common tools)
source ~/zzy/miniconda3/bin/activate wga

# If additional tools are needed, create a new conda environment
```

## Dependencies

- `liftOver` (UCSC Kent tools)
- `TElocal` / `TEtranscripts` (pip)
- `perl` (for makeTEgtf.pl)
- Standard Unix tools: `awk`, `sed`, `gzip`

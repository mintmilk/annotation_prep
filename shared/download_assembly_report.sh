#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

REPORT_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/016/699/485/GCF_016699485.2_bGalGal1.mat.broiler.GRCg7b/GCF_016699485.2_bGalGal1.mat.broiler.GRCg7b_assembly_report.txt"
REPORT_FILE="assembly_report.txt"
MAPPING_FILE="refseq_to_ensembl.tsv"

# Download assembly report
echo "Downloading assembly report..."
curl -L -o "$REPORT_FILE" "$REPORT_URL"

# Parse: extract assembled-molecule rows, map RefSeq accession → Ensembl chr name
# Assembly report columns (tab-separated):
#   1: Sequence-Name, 2: Sequence-Role, 3: Assigned-Molecule, 4: Assigned-Molecule-loc/type,
#   5: GenBank-Accn, 6: Relationship, 7: RefSeq-Accn, 8: Assembly-Unit,
#   9: Sequence-Length, 10: UCSC-style-name
echo "Parsing RefSeq → Ensembl chromosome name mapping..."
awk -F'\t' '
    /^#/ { next }
    $2 == "assembled-molecule" {
        refseq = $7
        # Sequence-Name (col1) has Ensembl-style names (1, 2, ..., W, Z)
        ensembl = $1
        # Special case: MT chromosome
        if (ensembl == "MT" || $4 == "Mitochondrion") ensembl = "MT"
        print refseq "\t" ensembl
    }
' "$REPORT_FILE" > "$MAPPING_FILE"

n_chr=$(wc -l < "$MAPPING_FILE")
echo "Created $MAPPING_FILE with $n_chr chromosome mappings"
head -5 "$MAPPING_FILE"

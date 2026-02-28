#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RAW_DIR="raw"
OUTPUT_DIR="output"
SHARED_DIR="../shared"
CHAIN="${RAW_DIR}/galGal6ToGCF_016699485.2.over.chain.gz"
MAPPING="${SHARED_DIR}/refseq_to_ensembl.tsv"

mkdir -p "$OUTPUT_DIR"

# Verify required files exist
for f in "$CHAIN" "$MAPPING"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: Required file not found: $f"
        echo "Run the download scripts first."
        exit 1
    fi
done

# Find all chromatin state BED files
# ChromHMM output files are typically named like: {tissue}_15_segments.bed
BED_FILES=$(find "$RAW_DIR" -name "*_segments.bed" -o -name "*_dense.bed" | sort)

if [[ -z "$BED_FILES" ]]; then
    # Fallback: look for any BED files in raw/
    BED_FILES=$(find "$RAW_DIR" -name "*.bed" | sort)
fi

if [[ -z "$BED_FILES" ]]; then
    echo "ERROR: No BED files found in $RAW_DIR"
    echo "Contents of $RAW_DIR:"
    ls -R "$RAW_DIR"
    exit 1
fi

echo "Found BED files:"
echo "$BED_FILES"
echo ""

# Enhancer state labels (ChromHMM 15-state model)
# E6=EnhA, E7=EnhAMe, E8=EnhAWk, E9=EnhAHet, E10=EnhPois
# Match both numeric (E6-E10) and text labels
ENHANCER_PATTERN="^(E[6-9]|E10|EnhA|EnhAMe|EnhAWk|EnhAHet|EnhPois)"

for bed_file in $BED_FILES; do
    tissue_name=$(basename "$bed_file" | sed 's/_[0-9]*_segments\.bed$//' | sed 's/_dense\.bed$//' | sed 's/\.bed$//')
    echo "=== Processing: $tissue_name ==="

    # Step 1: Extract enhancer regions (state label is typically in column 4)
    echo "  Extracting enhancer regions..."
    awk -v pat="$ENHANCER_PATTERN" '$4 ~ pat {print $1, $2, $3, $4}' OFS='\t' "$bed_file" \
        > "${OUTPUT_DIR}/${tissue_name}_enhancer_galGal6.bed"

    n_enh=$(wc -l < "${OUTPUT_DIR}/${tissue_name}_enhancer_galGal6.bed")
    echo "  Found $n_enh enhancer regions"

    if [[ "$n_enh" -eq 0 ]]; then
        echo "  WARNING: No enhancer regions found. Checking state labels in file:"
        cut -f4 "$bed_file" | sort -u | head -20
        echo "  Skipping this tissue."
        rm -f "${OUTPUT_DIR}/${tissue_name}_enhancer_galGal6.bed"
        continue
    fi

    # Step 2: LiftOver galGal6 → GRCg7b (RefSeq accessions)
    echo "  Running liftOver..."
    liftOver \
        "${OUTPUT_DIR}/${tissue_name}_enhancer_galGal6.bed" \
        "$CHAIN" \
        "${OUTPUT_DIR}/${tissue_name}_enhancer_refseq.bed" \
        "${OUTPUT_DIR}/${tissue_name}_enhancer_unmapped.bed"

    n_mapped=$(wc -l < "${OUTPUT_DIR}/${tissue_name}_enhancer_refseq.bed")
    n_unmapped=$(grep -c "^[^#]" "${OUTPUT_DIR}/${tissue_name}_enhancer_unmapped.bed" || true)
    echo "  Mapped: $n_mapped, Unmapped: $n_unmapped"

    # Step 3: Rename chromosomes RefSeq → Ensembl and remove scaffolds
    echo "  Renaming chromosomes and removing scaffolds..."
    awk -F'\t' '
        NR == FNR { map[$1] = $2; next }
        $1 in map { $1 = map[$1]; print }
    ' OFS='\t' "$MAPPING" "${OUTPUT_DIR}/${tissue_name}_enhancer_refseq.bed" \
        | sort -k1,1V -k2,2n \
        > "${OUTPUT_DIR}/${tissue_name}_enhancer_grcg7b.bed"

    n_final=$(wc -l < "${OUTPUT_DIR}/${tissue_name}_enhancer_grcg7b.bed")
    echo "  Final regions (Ensembl chr): $n_final"

    # Clean up intermediate files
    rm -f "${OUTPUT_DIR}/${tissue_name}_enhancer_galGal6.bed" \
          "${OUTPUT_DIR}/${tissue_name}_enhancer_refseq.bed" \
          "${OUTPUT_DIR}/${tissue_name}_enhancer_unmapped.bed"

    echo ""
done

echo "=== Done ==="
echo "Output files:"
ls -lh "$OUTPUT_DIR"/*.bed 2>/dev/null || echo "No output files generated."

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RAW_DIR="raw"
OUTPUT_DIR="output"
SHARED_DIR="../shared"
MAPPING="${SHARED_DIR}/refseq_to_ensembl.tsv"

mkdir -p "$OUTPUT_DIR"

RM_OUT_GZ="${RAW_DIR}/GCF_016699485.2.repeatMasker.out.gz"
RM_OUT="${RAW_DIR}/GCF_016699485.2.repeatMasker.out"
MAKE_TE_GTF="${RAW_DIR}/makeTEgtf.pl"

# Verify required files exist
for f in "$RM_OUT_GZ" "$MAKE_TE_GTF" "$MAPPING"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: Required file not found: $f"
        echo "Run the download scripts first."
        exit 1
    fi
done

# Step 1: Decompress RepeatMasker output
echo "Decompressing RepeatMasker output..."
gunzip -fk "$RM_OUT_GZ"

# Step 2: Convert .out → GTF using makeTEgtf.pl
# makeTEgtf.pl uses 1-based column indices after whitespace-split:
#   col5=chr, col6=start, col7=end, col9=strand, col10=TE_name, col11=class/family
# Skip 3 header lines; -1 for 1-based genomic coords in RM output
echo "Converting RepeatMasker .out to GTF..."
tail -n +4 "$RM_OUT" \
    | /usr/bin/perl "$MAKE_TE_GTF" -c 5 -s 6 -e 7 -o 9 -t 10 -f 11 -n GRCg7b_rmsk -1 /dev/stdin \
    2>/dev/null \
    > "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq.gtf"

echo "Raw GTF lines: $(wc -l < "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq.gtf")"

# Step 2b: Fix family_id and class_id (column 11 has "class/family" combined)
# Split "LINE/CR1" → class_id "LINE", family_id "CR1"
echo "Splitting class/family attributes..."
sed -E 's/family_id "([^/]+)\/([^"]+)"; class_id "[^"]+";/family_id "\2"; class_id "\1";/g' \
    "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq.gtf" \
    > "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq_fixed.gtf"
mv "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq_fixed.gtf" "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq.gtf"

# Step 3: Rename chromosomes RefSeq → Ensembl and remove scaffolds
echo "Renaming chromosomes and removing scaffolds..."
awk -F'\t' '
    NR == FNR { map[$1] = $2; next }
    $1 in map { $1 = map[$1]; print }
' OFS='\t' "$MAPPING" "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq.gtf" \
    > "${OUTPUT_DIR}/GRCg7b_rmsk_TE.gtf"

n_final=$(wc -l < "${OUTPUT_DIR}/GRCg7b_rmsk_TE.gtf")
echo "Final GTF lines (Ensembl chr only): $n_final"

# Clean up intermediate files
rm -f "$RM_OUT" "${OUTPUT_DIR}/GRCg7b_rmsk_TE_refseq.gtf"

echo "Output: ${OUTPUT_DIR}/GRCg7b_rmsk_TE.gtf"
echo "Sample lines:"
head -3 "${OUTPUT_DIR}/GRCg7b_rmsk_TE.gtf"

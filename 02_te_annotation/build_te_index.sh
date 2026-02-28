#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

OUTPUT_DIR="output"
TE_GTF="${OUTPUT_DIR}/GRCg7b_rmsk_TE.gtf"
TE_INDEX="${OUTPUT_DIR}/GRCg7b_rmsk_TE.locInd"

if [[ ! -f "$TE_GTF" ]]; then
    echo "ERROR: TE GTF not found: $TE_GTF"
    echo "Run build_te_gtf.sh first."
    exit 1
fi

# Build TElocal index (pickle the TEindex object)
echo "Building TElocal index from $TE_GTF..."
python - "$TE_GTF" "$TE_INDEX" <<'PYEOF'
import sys
import pickle
from TElocal_Toolkit.TEindex import TEfeatures

gtf_file = sys.argv[1]
index_file = sys.argv[2]

te_idx = TEfeatures()
te_idx.build(gtf_file)

with open(index_file, 'wb') as f:
    pickle.dump(te_idx, f)

print(f"TElocal index written to {index_file}")
PYEOF

ls -lh "$TE_INDEX"
echo "Done."

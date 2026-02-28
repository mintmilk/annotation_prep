#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RAW_DIR="raw"
mkdir -p "$RAW_DIR"

# Download Chromatin state ZIPs from Figshare (Pan et al. 2023)
echo "Downloading chromatin state files from Figshare..."
curl -L -o "${RAW_DIR}/Chromatin_state_1.zip" "https://ndownloader.figshare.com/files/35778266"
curl -L -o "${RAW_DIR}/Chromatin_state_2.zip" "https://ndownloader.figshare.com/files/35778269"
curl -L -o "${RAW_DIR}/Chromatin_state_3.zip" "https://ndownloader.figshare.com/files/35778272"

# Unzip chromatin state files
echo "Unzipping chromatin state files..."
for zip in "${RAW_DIR}"/Chromatin_state_*.zip; do
    unzip -o "$zip" -d "$RAW_DIR"
done

# Download liftOver chain file (galGal6 → GRCg7b/GCF_016699485.2)
echo "Downloading liftOver chain file..."
curl -L -o "${RAW_DIR}/galGal6ToGCF_016699485.2.over.chain.gz" \
    "https://hgdownload.soe.ucsc.edu/goldenPath/galGal6/liftOver/galGal6ToGCF_016699485.2.over.chain.gz"

echo "Download complete. Contents of raw/:"
ls -lh "$RAW_DIR"

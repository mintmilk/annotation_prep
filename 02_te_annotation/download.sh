#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RAW_DIR="raw"
mkdir -p "$RAW_DIR"

# Download RepeatMasker output for GRCg7b
echo "Downloading RepeatMasker output..."
curl -L -o "${RAW_DIR}/GCF_016699485.2.repeatMasker.out.gz" \
    "https://hgdownload.soe.ucsc.edu/hubs/GCF/016/699/485/GCF_016699485.2/GCF_016699485.2.repeatMasker.out.gz"

# Download makeTEgtf.pl (community version from TEtranscripts GitHub issue #83)
# Original labshare.cshl.edu URL is no longer available
echo "Downloading makeTEgtf.pl..."
curl -L -o "${RAW_DIR}/makeTEGTF.pl.gz" \
    "https://github.com/mhammell-laboratory/TEtranscripts/files/5610260/makeTEGTF.pl.gz"
gunzip -f "${RAW_DIR}/makeTEGTF.pl.gz"
mv "${RAW_DIR}/makeTEGTF.pl" "${RAW_DIR}/makeTEgtf.pl"
chmod +x "${RAW_DIR}/makeTEgtf.pl"

echo "Download complete. Contents of raw/:"
ls -lh "$RAW_DIR"

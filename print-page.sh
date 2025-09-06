#!/bin/bash
# Script to print HP DeskJet test page

# Resolve config file from current directory
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$CURRENT_DIR/config.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Please run install.sh first."
    exit 1
fi

# --- Read config values ---
INSTALL_DIR=$(awk -F' *= *' '/^install_dir/ {print $2}' "$CONFIG_FILE")
SAMPLE_PDF=$(awk -F' *= *' '/^sample_pdf/ {print $2}' "$CONFIG_FILE")
PRINTER_NAME=$(awk -F' *= *' '/^printer_name/ {print $2}' "$CONFIG_FILE")

SAMPLE_PDF_PATH="$INSTALL_DIR/$SAMPLE_PDF"


# Send job to printer
/usr/bin/lp -d "$PRINTER_NAME" "$SAMPLE_PDF_PATH"


#!/bin/bash

# Show differences between ./base and current system files
# Simple rsync-style output

set -e

# Load shared configuration
source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"

# Check if base directory exists
if [[ ! -d "$BASE_DIR" ]]; then
    error "Base directory not found: $BASE_DIR"
    error "Run ./backup.sh first to populate the base directory"
    exit 1
fi

RSYNC_OPTIONS="--dry-run --itemize-changes --recursive"

log "backup.sh (system → base) would change"
cd "$HOME"
rsync $RSYNC_OPTIONS ${HOME_FILES[@]} "$BASE_DIR/" 2>/dev/null || true

cd "$HOME/.config"
rsync $RSYNC_OPTIONS ${CONFIG_FILES[@]} "$BASE_DIR/.config/" 2>/dev/null || true

cd "$HOME/bin"
rsync $RSYNC_OPTIONS ${BIN_FILES[@]} "$BASE_DIR/bin/" 2>/dev/null || true

log "restore.sh (base → system) would change"
if [[ -d "$BASE_DIR" ]]; then
    cd "$BASE_DIR"
    rsync $RSYNC_OPTIONS ${HOME_FILES[@]} "$HOME/" 2>/dev/null || true
fi

if [[ -d "$BASE_DIR/.config" ]]; then
    cd "$BASE_DIR/.config"
    rsync $RSYNC_OPTIONS ${CONFIG_FILES[@]} "$HOME/.config/" 2>/dev/null || true
fi

if [[ -d "$BASE_DIR/bin" ]]; then
    cd "$BASE_DIR/bin"
    rsync $RSYNC_OPTIONS ${BIN_FILES[@]} "$HOME/bin/" 2>/dev/null || true
fi

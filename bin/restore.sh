#!/bin/bash

# Restore dotfiles from ./base to ~/
# This script syncs configurations from the repository to your system

set -e

# Load shared configuration
source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"

BACKUP_DIR="$DOTFILES_DIR/backup"
RSYNC_OPTIONS="-av"

# Check if base directory exists
if [[ ! -d "$BASE_DIR" ]]; then
    error "Base directory not found: $BASE_DIR"
    error "Run ./backup.sh first to populate the base directory"
    exit 1
fi

# Create backup of existing files (optional safety feature)
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_DIR/$timestamp"

    log "backing up current configs"
    mkdir -p "$backup_dir"

    # Backup existing home dotfiles
    for file in ${HOME_FILES[@]}; do
        if [[ -e "$HOME/$file" ]]; then
            cp -r "$HOME/$file" "$backup_dir/"
        fi
    done

    # Backup existing config directories
    for dir in ${CONFIG_FILES[@]}; do
        if [[ -d "$HOME/.config/$dir" ]]; then
            cp -r "$HOME/.config/$dir" "$backup_dir/"
        fi
    done

    # Backup existing bin files
    mkdir -p "$backup_dir/bin"
    for file in ${BIN_FILES[@]}; do
        if [[ -f "$HOME/bin/$file" ]]; then
            cp "$HOME/bin/$file" "$backup_dir/bin/"
        fi
    done

    success "backup created at $backup_dir"
}

# Main restore function
restore_dotfiles() {
    log "restoring dotfiles from $BASE_DIR"

    # Ensure target directories exist
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/bin"

    # Restore home directory dotfiles
    if [[ -d "$BASE_DIR" ]]; then
        log "~"
        cd "$BASE_DIR"
        rsync $RSYNC_OPTIONS \
            ${HOME_FILES[@]} \
            "$HOME/"
    fi

    # Restore config directories
    if [[ -d "$BASE_DIR/.config" ]]; then
        log "~/.config"
        cd "$BASE_DIR/.config"
        rsync $RSYNC_OPTIONS \
            ${CONFIG_FILES[@]} \
            "$HOME/.config/"
    fi

    # Restore bin files
    if [[ -d "$BASE_DIR/bin" ]]; then
        log "~/bin"
        cd "$BASE_DIR/bin"
        rsync $RSYNC_OPTIONS \
            ${BIN_FILES[@]} \
            "$HOME/bin/"
        chmod +x "$HOME/bin"/${BIN_FILES[@]}
    fi

    success "dotfiles restored"
}

# Parse arguments
BACKUP_FIRST=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--backup)
            BACKUP_FIRST=true
            shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Restore dotfiles from ./base to system"
            echo ""
            echo "Options:"
            echo "  -b, --backup     Create backup before restoring"
            echo "  -h, --help   Show this help"
            exit 0 ;;
        *)
            error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1 ;;
    esac
done

if [[ "$BACKUP_FIRST" == true ]]; then
    create_backup
fi

restore_dotfiles

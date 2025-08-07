#!/bin/bash

# Backup current system configs to repo
# This script syncs configurations from the repository to your system

set -e

# Load shared configuration
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Create base directory if it doesn't exist
mkdir -p $BASE_DIR/.config

log "Backing up system configs to $BASE_DIR"

# home folder
log "Backing up home dotfiles..."
cd ~
rsync -av \
  ${HOME_FILES[@]} \
  $BASE_DIR

# config folder
log "Backing up config directories..."
cd ~/.config
rsync -av \
  ${CONFIG_FILES[@]} \
  $BASE_DIR/.config

success "Backup completed!"

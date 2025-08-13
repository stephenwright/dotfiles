#!/bin/bash

# Shared configuration for dotfiles scripts
# Source this file in backup.sh, restore.sh, and diff.sh

# Directory paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$DOTFILES_DIR/base"

# Files to sync from ~/
HOME_FILES=(
    .aliases
    .profile
    .tmux.conf
    .vim
    .zshrc
)

# files to sync from ~/.config/
CONFIG_FILES=(
    foot
    fuzzel
    hypr
    mako
    nvim
    waybar
)

# Files to sync from ~/bin/
BIN_FILES=(
    stew
    stew-wall
    stew-space
    stew-session
    stew-win
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}$1${NC}"; }
warn() { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }

#!/bin/bash

# Show differences between ./base and current system files
# Enhanced diff with better output and actual content differences

set -e

# Load shared configuration
source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"

# Check if base directory exists
if [[ ! -d "$BASE_DIR" ]]; then
    error "Base directory not found: $BASE_DIR"
    error "Run ./backup.sh first to populate the base directory"
    exit 1
fi

# Options
MODE=""
RSYNC_OPTIONS="--dry-run --itemize-changes --recursive --human-readable"

# Function to get file differences with actual content
show_file_diff() {
    local file1="$1"
    local file2="$2"
    local label="$3"

    if [[ -f "$file1" && -f "$file2" ]]; then
        if ! cmp -s "$file1" "$file2"; then
            log "### $label: $(basename "$file1")"
            if [[ "$MODE" == "full" ]]; then
                diff -u "$file1" "$file2" 2>/dev/null || true
            else
                echo "Files differ (use 'full' option to see details)"
            fi
            echo ""
        fi
    elif [[ -f "$file1" && ! -f "$file2" ]]; then
        log "### $label: $(basename "$file1")"
        echo "Only in system (not in base)"
        echo ""
    elif [[ ! -f "$file1" && -f "$file2" ]]; then
        log "### $label: $(basename "$file1")"
        echo "Only in base (not in system)"
        echo ""
    fi
}

# Function to compare directories
compare_directories() {
    local section_name="$1"
    local base_dir="$2"
    local system_dir="$3"
    local files_array=("${@:4}")  # All parameters from 4 onwards

    log "## $section_name Differences"

    if [[ "$MODE" == "full" ]]; then
        # Show file-by-file differences with full content
        for item in "${files_array[@]}"; do
            if [[ -f "$system_dir/$item" || -f "$base_dir/$item" ]]; then
                show_file_diff "$system_dir/$item" "$base_dir/$item" "$section_name"
            elif [[ -d "$system_dir/$item" && -d "$base_dir/$item" ]]; then
                # Handle directories recursively
                find "$system_dir/$item" -type f 2>/dev/null | while read -r file; do
                    rel_path="${file#$system_dir/}"
                    show_file_diff "$file" "$base_dir/$rel_path" "$section_name"
                done
            fi
        done
    else
        cd "$system_dir" 2>/dev/null || return
        local rsync_output
        rsync_output=$(rsync $RSYNC_OPTIONS "${files_array[@]}" "$base_dir/" 2>/dev/null || true)

        if [[ -n "$rsync_output" ]]; then
            echo "$rsync_output"
        else
            success "No differences found"
        fi
    fi
    echo ""
}

# Parse arguments
MODE=""
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [-f|--full]"
        echo ""
        echo "Options:"
        echo "  -f, --full     Show actual file content differences"
        echo ""
        echo "Examples:"
        echo "  $0           # Quick summary"
        echo "  $0 --full    # Full diff output with content"
        exit 0
        ;;
    -f|--full)
        MODE="full"
        ;;
    "")
        # No arguments - default mode
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

# Main comparison
log "# Dotfiles Difference Report"
echo ""

# Compare each section
compare_directories "Home Files" "$BASE_DIR" "$HOME" "${HOME_FILES[@]}"
compare_directories "Config Files" "$BASE_DIR/.config" "$HOME/.config" "${CONFIG_FILES[@]}"
compare_directories "Bin Files" "$BASE_DIR/bin" "$HOME/bin" "${BIN_FILES[@]}"

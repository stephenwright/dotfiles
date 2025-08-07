# dotfiles

Ever evolving linux configuration files.

Clean, simple dotfiles management with a unified command interface.

## Quick Start

```bash
# Backup current system configs to repo
./dot backup

# Show differences between base and system
./dot diff

# Restore configs from repo to system
./dot restore --backup
```

## Commands

Use the `./dot` script to manage your dotfiles:

| Command | Purpose | Direction |
|---------|---------|-----------|
| `./dot backup` | Save system configs to repo | `~/ → ./base/` |
| `./dot restore` | Apply repo configs to system | `./base/ → ~/` |
| `./dot diff` | Show differences | Compare base ↔ system |

### Usage Examples

```bash
# Backup your current configs
./dot backup

# See what's different
./dot diff

# Restore with safety backup
./dot restore --backup

# Get help for any command
./dot --help
./dot restore --help
```

## Folder Structure

```
.
├── archive/     # old dotfiles for tools no longer used
├── backup/      # safety backups created by restore
├── base/        # active dotfiles synced with system
│   ├── .config/ # configs that go in ~/.config/
│   └── ...      # files that go in ~/
├── env/         # environment-specific overrides (future use)
│   ├── work/    # work machine customizations
│   └── home/    # home machine customizations
├── bin/         # individual scripts
│   ├── backup.sh    # system → repo
│   ├── restore.sh   # repo → system
│   └── diff.sh      # compare differences
├── config.sh    # shared configuration
└── dot          # main command interface
```

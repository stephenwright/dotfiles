# dotfiles

Ever evolving linux configuration files.

Clean, simple dotfiles management with separate scripts for backup, restore, and diff operations.

## Quick Start

```bash
# Backup current system configs to repo
./backup.sh

# Show differences between base and system
./diff.sh

# Restore configs from repo to system
./restore.sh
```

## Folder Structure

```
.
├── archive/     # old dotfiles for tools no longer used
├── base/        # active dotfiles synced with system
│   ├── .config/ # configs that go in ~/.config/
│   └── ...      # files that go in ~/
├── env/         # environment-specific overrides (future use)
│   ├── work/    # work machine customizations
│   └── home/    # home machine customizations
├── backup.sh    # system → repo
├── restore.sh   # repo → system
├── diff.sh      # compare differences
└── config.sh    # shared configuration
```

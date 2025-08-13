# dotfiles

Ever evolving linux configuration files.

Clean, simple dotfiles management with a unified command interface.

## Folder Structure

```
.
├── archive/     # old dotfiles
├── backup/      # backups created by `restore --backup`
├── base/        # config files, structure mirrors $HOME
│   ├── bin/     # scripts
│   │   ├── dot           # tool for managing dotfiles
│   │   ├── dot-config    # configuration for what files get synced by `dot` helper
│   │   └── ...
│   └── ...
└── README.md    # this file
```

## dot: dotfiles management tool

```bash
# first time setup
cd ~/dotfiles/base/bin && ./dot restore

# Show differences between base and system
dot diff
dot diff --full  # Show actual content differences

# Backup current system configs to repo
dot backup

# Restore configs from repo to system
dot restore --backup
```

## stew: desktop environment management tool

```bash
stew wall            # Change wallpaper
stew space           # Apply workspace profile
stew session         # lock/logout/restart/shutdown
stew win             # Find and manage windows
```

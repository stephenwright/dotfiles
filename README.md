# dotfiles

Ever evolving linux configuration files.

Clean, simple dotfiles management with a unified command interface.

## Folder Structure

```
.
├── archive/     # old dotfiles
├── backup/      # backups created by `restore --backup`
├── base/        # config files, structure mirrors $HOME
├── bin/         # scripts
│   ├── dot      # tool for managing dotfiles
│   └── stew     # tool for managing environment
└── README.md    # this file
```

Note: These scripts assume repo is checked out to ~/dotfiles

## dot: dotfiles management tool

```bash
# first time setup
cd ~/dotfiles/bin && ./dot restore

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
stew notify     # show recent notifications
stew session    # lock/logout/restart/shutdown
stew space      # Apply workspace profile
stew wall       # Change wallpaper
stew win        # Find and manage windows
```

# dotfiles

Ever evolving linux configuration files.

Clean, simple dotfiles management with a unified command interface.

## Folder Structure

```
.
├── archive/      # old dotfiles
├── backup/       # backups created by `restore --backup`
├── base/         # config files, structure mirrors $HOME
├── bin/          # scripts
│   ├── dot       # tool for managing dotfiles
│   └── stew      # tool for managing environment
├── packages.txt  # packages installed by `dot install`
└── README.md     # this file
```

Note: These scripts assume repo is checked out to ~/dotfiles

## dot: dotfiles management tool

```bash
# first time setup
cd ~/dotfiles/bin
./dot install    # install packages listed in packages.txt
./dot restore    # apply configs from repo to ~

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
stew capture    # Screen-region capture to GIF
stew mux        # Multiplexer session profiles
stew notify     # Show recent notifications
stew profile    # Apply workspace/monitor profile
stew run        # Command runner (bare notifies, ';' terminal, ':' TUI)
stew session    # Lock/logout/restart/shutdown
stew wall       # Change wallpaper
stew win        # Find and manage windows
```

# options
#setopt correct                                                  # Auto correct mistakes
setopt extendedglob                                             # Extended globbing. Allows using regular expressions with *
setopt nocaseglob                                               # Case insensitive globbing
setopt rcexpandparam                                            # Array expension with parameters
setopt nocheckjobs                                              # Don't warn about running processes when exiting
setopt numericglobsort                                          # Sort filenames numerically when it makes sense
setopt nobeep                                                   # No beep
setopt appendhistory                                            # Immediately append history instead of overwriting
setopt histignorealldups                                        # If a new command is a duplicate, remove the older one
setopt sharehistory
setopt histnostore
setopt histsavenodups
setopt histverify
setopt autocd                                                   # if only directory path is entered, cd there.

# prompt
PS1="%(#.%F{red}.%F{green})%n%f@%m%F{cyan}%21<..<%~%<<%f%# "


# completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case insensitive tab completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"         # Colored completion (different colors for dirs/files/etc)
zstyle ':completion:*' rehash true                              # automatically find new executables in path 
# speed up completions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# history
HISTFILE=~/.zsh/histfile
HISTSIZE=1000
SAVEHIST=500

WORDCHARS=${WORDCHARS//\/[&.;]}                                 # Don't consider certain characters part of the word

# key bindins
bindkey -e
bindkey "\e[1~" beginning-of-line                               # Home
bindkey "\e[4~" end-of-line                                     # End
bindkey "\e[5~" beginning-of-history                            # PageUp
bindkey "\e[6~" end-of-history                                  # PageDown
bindkey "\e[2~" quoted-insert                                   # Ins
bindkey "\e[3~" delete-char                                     # Del

# Navigate words with ctrl+arrow keys
bindkey '^[Oc' forward-word                                     #
bindkey '^[Od' backward-word                                    #
bindkey '^[[1;5D' backward-word                                 #
bindkey '^[[1;5C' forward-word                                  #
bindkey '^H' backward-kill-word                                 # delete previous word with ctrl+backspace

# theming
autoload -U compinit colors zcalc
compinit -d
colors

# colour man pages
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-r

# fzf
source /usr/share/fzf/completion.zsh
source /usr/share/fzf/key-bindings.zsh

[ -f ~/.profile ] && source ~/.profile

# binsentry
[ -f /srv/binsentry/devroot/.binsentry.profile ] && source /srv/binsentry/devroot/.binsentry.profile


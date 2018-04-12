
# set a fancy prompt
#PS1="$(print '%{\e[0;32m%}%n%{\e[0m%}')@$(print '%{\e[0;33m%}%m%{\e[0m%}')%20<..<:$(print '%{\e[1;36m%}%~%{\e[0m%}')% $ "
PS1="%21<..<:$(print '%{\e[1;36m%}%~%{\e[0m%}')% $ "

# include completion options
source ~/.zsh/completion

autoload -Uz compinit
compinit

# set history buffer
HISTFILE=~/.zsh/histfile
HISTSIZE=SAVEHIST=1000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

# set aliases
source ~/.aliases

# disable zsh's auto-correct feature
unsetopt correct_all

# if using oh-my-zsh, set the theme to gentoo
ZSH_THEME="gentoo"

# convenience function for find
f() {
    echo "find . -iname \"*$1*\""
    find . -iname "*$1*"
}

# add ~/bin to the path if it exists
if [ -d ~/bin ] ; then
    PATH=~/bin:"${PATH}"
fi

bindkey -e

bindkey "\e[1~" beginning-of-line # Home
bindkey "\e[4~" end-of-line # End
bindkey "\e[5~" beginning-of-history # PageUp
bindkey "\e[6~" end-of-history # PageDown
bindkey "\e[2~" quoted-insert # Ins
bindkey "\e[3~" delete-char # Del

source ~/.profile

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# helper to append to $PATH without creating duplicates
pathmunge () {
  if ! echo $PATH | grep -E -q "(^|:)$1($|:)" ; then
    if [ "$2" = "after" ] ; then
      PATH=$PATH:$1
    else
      PATH=$1:$PATH
    fi
  fi
}

export EDITOR=$(command -v nvim || command -v vim || command -v vi)

# additional bin paths, if it's present
[ -d "$HOME/bin" ] && pathmunge "$HOME/bin"
[ -d "$HOME/.local/bin" ] && pathmunge "$HOME/.local/bin"
[ -d "$HOME/.cargo/bin" ] && pathmunge "$HOME/.cargo/bin"

# aliases
[ -f ~/.aliases ] && source ~/.aliases

# cleanup
unset -f pathmunge


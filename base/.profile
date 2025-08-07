# helper to append to $PATH without creating duplicates
pathmunge () {
  if ! echo $PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
    if [ "$2" = "after" ] ; then
      PATH=$PATH:$1
    else
      PATH=$1:$PATH
    fi
  fi
}

# convenience function for find
f() {
    echo "find . -iname \"*$1*\""
    find . -iname "*$1*"
}

export QT_QPA_PLATFORMTHEME="qt5ct"
export EDITOR=/usr/bin/vim

# add ~/bin to path if it's present
[ -d "$HOME/bin" ] && pathmunge "$HOME/bin"

# aliases
source ~/.aliases

# cleanup
unset -f pathmunge

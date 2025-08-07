# make sure the destination exists
mkdir -p ~/dotfiles/base/.config

# home directory dotfiles
cd ~
rsync -av \
  .aliases \
  .profile \
  .tmux.conf \
  .vim \
  .zshrc \
  ~/dotfiles/base

# config folder
cd ~/.config
rsync -av \
  foot \
  fuzzel \
  hypr \
  mako \
  nvim \
  waybar \
  ~/dotfiles/base/.config

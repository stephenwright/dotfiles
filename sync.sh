# make sure the destination exists
mkdir -p ~/dotfiles/.config

# home directory dotfiles
cd ~ 
rsync -av \
  .aliases \
  .profile \
  .tmux.conf \
  .vim \
  .zshrc \
  .Xresources \
  ~/dotfiles

# config folder
cd ~/.config
rsync -av \
  alacritty \
  hypr \
  i3 \
  i3status \
  mako \
  nitrogen \
  nvim \
  polybar \
  waybar \
  wofi \
  ~/dotfiles/.config


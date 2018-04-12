# make sure the destination exists
mkdir -p ~/dotfiles/.config

# home directory dotfiles
cd ~ 
rsync -av \
  .aliases \
  .profile \
  .tmux.conf \
  .vimrc \
  .zshrc \
  .Xresources \
  ~/dotfiles

# config folder
cd ~/.config
rsync -av \
  i3 \
  i3status \
  nitrogen \
  polybar \
  ~/dotfiles/.config


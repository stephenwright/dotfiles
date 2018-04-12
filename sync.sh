cd ~ 
rsync -av \
  .aliases \
  .profile \
  .tmux.conf \
  .vimrc \
  .zshrc \
  .Xresources \
  dotfiles

cd ~/.config
rsync -av \
  i3 \
  i3status \
  nitrogen \
  polybar \
  ~/dotfiles/.config


#!/bin/sh

echo "DOTFILES SETUP START"

for f in .??*; do
  [ "$f" = ".git" ] && continue
  [ "$f" == ".DS_Store" ] && continue
  ln -snfv ~/dotfiles/"$f" ~/
done

echo "installing homebrew..."
which brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

if which brew >/dev/null 2>&1; then
  echo "run brew doctor..."
  brew doctor

  echo "run brew update..."
  brew update

  echo "run brew bundle install"
  brew bundle install --file=~/.config/Brewfile

  echo "set shell zsh"
  sudo sh -c "echo $(brew --prefix)/bin/zsh >> /etc/shells"
  chsh -s $(brew --prefix)/bin/zsh
else
  echo "homebrew is already installed"
fi

echo "DOTFILES SETUP FINISHED"

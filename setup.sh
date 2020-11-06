#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "DOTFILES SETUP START"

for f in .??*; do
  [ "$f" == ".git" ] && continue
  [ "$f" == ".DS_Store" ] && continue
  [ "$f" == ".gitignore" ] && continue
  ln -snfv "$SCRIPT_DIR/$f" ~
done

echo "installing homebrew..."
which brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

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
  
  echo "installing nodebrew from homebrew"
  export PATH="$PATH:$HOME/.nodebrew/current/bin"
  if which nodebrew >/dev/null 2>&1; then
    nodebrew setup
    nodebrew install-binary stable
    nodebrew use stable
    if which npm >/dev/null 2>&1; then
      npm install -g yarn gatsby-cli expo-cli
    fi
  else
    echo "nodebrew install failed" 
  fi

else
  echo "homebrew is already installed"
fi

echo "DOTFILES SETUP FINISHED"

echo "Install zplugin START"
mkdir ~/.zplugin
git clone https://github.com/zdharma/zplugin.git ~/.zplugin/bin
echo "Install zplugin FINISHED"
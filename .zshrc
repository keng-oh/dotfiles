# Created by newuser for 5.7.1

# 日本語を使用
export LANG=ja_JP.UTF-8

# add PATH
export PATH="$HOME/bin:$PATH"

# add Alias
source ~/.alias

# colorful
autoload -Uz colors
colors

# 他のターミナルとヒストリーを共有
setopt share_history

# Ctrl+Dでログアウトしてしまうことを防ぐ
setopt IGNOREEOF

# setting zsh-completions
if [ -e /usr/local/share/zsh-completions ]; then
    fpath=(/usr/local/share/zsh-completions $fpath)
fi

# correct command
setopt correct

# プロンプトを2行で表示、時刻を表示
PROMPT="%(?.%{${fg[green]}%}.%{${fg[red]}%})%n${reset_color}@${fg[blue]}%m${reset_color}(%*%) %~
%# "
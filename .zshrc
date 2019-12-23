# Created by newuser for 5.7.1

# 日本語を使用
export LANG=ja_JP.UTF-8

# add PATH
export PATH="$HOME/bin:$PATH"

# add Alias
source ~/.alias

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

# customize PROMPT
# -----------------------------
# Prompt
# -----------------------------
# %M    ホスト名
# %m    ホスト名
# %d    カレントディレクトリ(フルパス)
# %~    カレントディレクトリ(フルパス2)
# %C    カレントディレクトリ(相対パス)
# %c    カレントディレクトリ(相対パス)
# %n    ユーザ名
# %#    ユーザ種別
# %?    直前のコマンドの戻り値
# %D    日付(yy-mm-dd)
# %W    日付(yy/mm/dd)
# %w    日付(day dd)
# %*    時間(hh:flag_mm:ss)
# %T    時間(hh:mm)
# %t    時間(hh:mm(am/pm))
# and more -> https://www.sirochro.com/note/terminal-zsh-prompt-customize/

## colorful
autoload -Uz colors
colors

## vcs_info for git info
autoload -Uz vcs_info
setopt prompt_subst

## git info
zstyle ':vcs_info:git:*' check-for-changes true #formats 設定項目で %c,%u が使用可
zstyle ':vcs_info:git:*' stagedstr "%F{green}!" #commit されていないファイルがある
zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+" #add されていないファイルがある
zstyle ':vcs_info:*' formats "%F{cyan}%c%u(%b)%f" #通常
zstyle ':vcs_info:*' actionformats '[%b|%a]' #rebase 途中,merge コンフリクト等 formats 外の表示

precmd () { vcs_info }

## Left side
PROMPT="%(?.%{${fg[green]}%}.%{${fg[red]}%})%n${reset_color}@${fg[blue]}%m${reset_color}(%*%) %~
%# "
## Right side
# RPROMPT="%{${fg[red]}%}[%~]%{${reset_color}%}"
RPROMPT=""
RPROMPT=$RPROMPT"${vcs_info_msg_0_}%{${reset_color}%}"
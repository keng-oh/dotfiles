# dotfiles プロジェクト

chezmoi による開発環境設定リポジトリ。対応環境は2系統:

- **デスクトップ**: Arch Linux (CachyOS) + Hyprland — パッケージは pacman / paru
- **サーバー**: Debian / Ubuntu 系 (Proxmox VE ホストなど) — パッケージは apt、
  apt に無いものは mise

環境の判定は `.chezmoi.osRelease.id` が `cachyos` かどうかで行う。

## 構成

- `.chezmoiroot` - chezmoiのソースを `home/` に指定
- `home/` - chezmoiソースディレクトリ(`~` に展開される)
  - `dot_zshrc` / `dot_zshenv.tmpl` - zsh設定・環境変数
    (zshenvのデスクトップ用変数はCachyOS分岐内。サーバーには`LANG`と
    `~/.local/bin`・mise shims の PATH のみ配置)
  - `dot_config/hypr/` - Hyprland設定(hyprland.conf, powermenu, 壁紙スクリプト)
  - `dot_config/waybar/` `wofi/` `swaync/` - デスクトップUI設定
  - `dot_config/wezterm/` `zellij/` - ターミナル設定
  - `dot_config/fcitx5/` - 日本語入力設定(コピー配置なのでfcitx5が書き込み可能)
  - `dot_config/packages/pacman.txt` / `aur.txt` / `apt.txt` - パッケージリスト
  - `dot_config/mise/config.toml` - mise管理ツール(サーバー用。CachyOSでは未配置)
  - `private_dot_ssh/` - SSH設定と公開鍵(秘密鍵は1Password管理でマシン上に無い)
  - `.chezmoiscripts/` - セットアップスクリプト(run_once/run_onchange)
  - `.chezmoiignore` - **環境ごとの配置除外はすべてここに集約**
  - `.chezmoiremove` - 旧Home Manager残骸の削除リスト
- `wallpapers/` - 壁紙(スクリプトから `~/repos/dotfiles/wallpapers` 参照)
- `init.sh` - 新規マシン用ブートストラップ
- `Makefile` - 管理用コマンド

chezmoiのソースディレクトリはこのリポジトリ自体
(`~/.config/chezmoi/chezmoi.toml` の `sourceDir` で指定)。

## よく使うコマンド

- `make switch` (= `chezmoi apply`) - 設定を適用
- `make diff` (= `chezmoi diff`) - 適用される差分を確認
- `make update` - リポジトリ + パッケージ更新(paru前提のためCachyOS専用)
- `make install` - 初回セットアップ(新規マシン)

## 編集時の注意

- 設定ファイルの編集は `home/` 以下のソースを直接編集し、`chezmoi apply` で反映
- パッケージ追加先:
  - CachyOS: `pacman.txt`(公式)または `aur.txt`(AUR)。
    追加前に `paru -Si <名前>` で実在確認すること
  - サーバー: `apt.txt`。apt に無いものは `dot_config/mise/config.toml`
  - リスト変更時は apply で自動インストールされる
    (`run_onchange_before_10-packages.sh.tmpl` / `run_onchange_after_21-mise.sh.tmpl`)
- `home/` 内のファイル名はchezmoi規約(`dot_` = `.`、`executable_` = 実行可能、
  `private_` = パーミッション制限)
- 適用前に `chezmoi diff` で差分確認するのが安全

## パッケージ管理の方針

- **CachyOS**: 公式リポジトリにあるものは `pacman.txt`、AURのみは `aur.txt`
- **サーバー(apt)**: `apt.txt`。apt に無い CLI ツール(eza / zellij / lazygit /
  lazydocker / delta / navi / yazi)と言語ランタイム(node / go / ruby / php)は
  mise で管理する
- 公式インストールスクリプト経由のもの:
  - Tailscale(`run_once_after_20-tailscale.sh`。systemd/root統合が必要なため)
  - starship と Claude Code(`run_onchange_before_10-packages.sh.tmpl` の apt 分岐。
    npm版 Claude Code は postinstall 依存のランチャーなので使わない)
- Android SDKは `/opt/android-sdk` にAURパッケージで配置し、
  初期化は `run_once_after_40-android-sdk.sh` が行う

## 環境ごとの分岐の書き方

**配置するかどうかの分岐は `.chezmoiignore` に書き、スクリプト内に
OS判定を重複させない。** 両方に書くと片方だけ直したときにスクリプトが
黙って何もしない状態になる。

`.chezmoiignore` は2ブロック構成:

- `{{ if ne ... "cachyos" }}` — デスクトップ専用のものをサーバーから除外
  (Hyprland / waybar / fcitx5 等、`.ssh/**`、ntfy・rclone、Arch専用スクリプト)
- `{{ if eq ... "cachyos" }}` — サーバー専用のものをデスクトップから除外
  (mise関連)

スクリプト内のテンプレート分岐は、**同一スクリプト内で処理内容が分かれる場合のみ**
使う(例: `10-packages` の pacman 分岐と apt 分岐)。

## sudo の扱い

Proxmox VE のように **root が正規の管理者で sudo が入っていない**環境がある。
分岐を各所に持たせず、`init.sh` の冒頭で sudo が無ければ導入し、
以降のスクリプトはすべて `sudo` があることを前提に書く
(`apt.txt` にも `sudo` を入れて維持する)。

例外は Claude Code の公式インストーラで、`$HOME` 配下に入れる作りのため
sudo を付けてはいけない。

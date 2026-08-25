# dotfiles プロジェクト

chezmoi + pacman/paru による開発環境設定リポジトリ。
使用環境: Arch Linux (CachyOS) + Hyprland。
(以前は Nix + Home Manager 管理。移行中の手順は `MIGRATION.md` 参照)

## 構成

- `.chezmoiroot` - chezmoiのソースを `home/` に指定
- `home/` - chezmoiソースディレクトリ(`~` に展開される)
  - `dot_zshrc` / `dot_zshenv.tmpl` - zsh設定・環境変数
    (zshenvのデスクトップ用変数はCachyOS分岐内。サーバーには`LANG`のみ配置)
  - `dot_config/hypr/` - Hyprland設定(hyprland.conf, powermenu, 壁紙スクリプト)
  - `dot_config/waybar/` `wofi/` `swaync/` - デスクトップUI設定
  - `dot_config/wezterm/` `zellij/` - ターミナル設定
  - `dot_config/fcitx5/` - 日本語入力設定(コピー配置なのでfcitx5が書き込み可能)
  - `dot_config/packages/pacman.txt` / `aur.txt` - パッケージリスト
  - `private_dot_ssh/` - SSH設定と公開鍵(秘密鍵は1Password管理でマシン上に無い)
  - `.chezmoiscripts/` - セットアップスクリプト(run_once/run_onchange)
  - `.chezmoiremove` - 旧Home Manager残骸の削除リスト
- `wallpapers/` - 壁紙(スクリプトから `~/repos/dotfiles/wallpapers` 参照)
- `init.sh` - 新規マシン用ブートストラップ
- `Makefile` - 管理用コマンド

chezmoiのソースディレクトリはこのリポジトリ自体
(`~/.config/chezmoi/chezmoi.toml` の `sourceDir` で指定)。

## よく使うコマンド

- `make switch` (= `chezmoi apply`) - 設定を適用
- `make diff` (= `chezmoi diff`) - 適用される差分を確認
- `make update` - リポジトリ + パッケージ更新
- `make install` - 初回セットアップ(新規マシン)

## 編集時の注意

- 設定ファイルの編集は `home/` 以下のソースを直接編集し、`chezmoi apply` で反映
- パッケージ追加は `home/dot_config/packages/pacman.txt`(公式)または `aur.txt`(AUR)に追記
  - リスト変更時は apply で自動インストールされる(`run_onchange_before_10-packages.sh.tmpl`)
  - 追加前に `paru -Si <名前>` で実在確認すること
- `home/` 内のファイル名はchezmoi規約(`dot_` = `.`、`executable_` = 実行可能、
  `private_` = パーミッション制限)
- 適用前に `chezmoi diff` で差分確認するのが安全

## パッケージ管理の方針

- 公式リポジトリ(CachyOS含む)にあるものは `pacman.txt`、AURのみは `aur.txt`
- Tailscaleのみ公式インストールスクリプト経由(`run_once_after_20-tailscale.sh`)
- Android SDKは `/opt/android-sdk` にAURパッケージで配置し、
  初期化は `run_once_after_40-android-sdk.sh` が行う

# dotfiles プロジェクト

Nix + Home Managerによるクロスプラットフォーム開発環境設定リポジトリ。
現在の主な使用環境: Arch Linux (CachyOS) + Hyprland。

## 構成

- `flake.nix` - Nix Flake エントリポイント（arch / ubuntu / ubuntu-server / mac）
- `common.nix` - 全プラットフォーム共通設定
- `modules/` - プラットフォーム別モジュール
  - `arch.nix` - Arch Linux固有設定（メイン）
  - `hyprland.nix` - Hyprland + Waybar + Mako + テーマ設定
  - `darwin.nix` - macOS固有設定
  - `ubuntu.nix` / `ubuntu-server.nix` - Ubuntu固有設定
  - `common/` - 共通モジュール群（git, zsh, cli-tools, wezterm, zellij）
- `hypr/` - Hyprland設定ファイル（hyprland.conf）
- `wezterm/` - WezTerm設定ファイル
- `zellij/` - Zellij設定ファイル
- `fcitx5/` - fcitx5設定ファイル（make switchでコピー適用）
- `Makefile` - セットアップ・管理用コマンド

## よく使うコマンド

- `make switch` - 設定を適用
- `make update` - flake更新 + 適用
- `make check` - 設定チェック（適用せず）
- `make install` - 初回セットアップ

## 編集時の注意

- Nix式の構文を守ること（`flake.nix`, `modules/*.nix`）
- Arch固有の設定は `modules/arch.nix`、macOS固有は `modules/darwin.nix`
- Hyprland関連（waybar, mako, テーマ等）は `modules/hyprland.nix`
- 変更後は `make check` で構文チェックしてから `make switch` で適用

## パッケージ管理の方針

- 基本は Nix (home.packages) で管理
- GUIアプリで Nix 版が GPU/OpenGL 問題を起こす場合は paru（AUR）で管理
  - PAM/D-Bus等システム統合が必要なパッケージ（Nix版だと`/usr/lib/security`等の標準パスに統合ファイルが置かれず機能しない）も同様に paru 管理にする
  - 現在 paru 管理: `google-chrome`, `wezterm-git`, `ttf-hackgen`, `xdg-desktop-portal-hyprland`, `docker`, `docker-compose`, `claude-desktop`, `gnome-keyring`
- fcitx5設定は `fcitx5/` 以下で管理し、make switch 時にコピー（シンボリックリンクにすると fcitx5 が書き込めないため）

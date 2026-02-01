# dotfiles プロジェクト

Nix + Home Managerによるクロスプラットフォーム開発環境設定リポジトリ。

## 構成

- `flake.nix` / `home.nix` - Nix Flake + Home Manager エントリポイント
- `modules/` - 各種設定モジュール（packages, git, zsh, cli-tools, wezterm, zellij, linux, darwin）
- `wezterm/` - WezTerm設定ファイル
- `zellij/` - Zellij設定ファイル
- `Makefile` - セットアップ・管理用コマンド

## よく使うコマンド

- `make switch` - 設定を適用
- `make update` - flake更新 + 適用
- `make check` - 設定チェック（適用せず）
- `make install` - 初回セットアップ

## 編集時の注意

- Nix式の構文を守ること（`home.nix`, `modules/*.nix`）
- Linux固有の設定は `modules/linux.nix`、macOS固有は `modules/darwin.nix`
- GUIアプリはLinux=Flatpak、macOS=Homebrew Cask で管理
- 変更後は `make check` で構文チェックしてから `make switch` で適用
- 設定の更新後、READMEやドキュメントも更新すること

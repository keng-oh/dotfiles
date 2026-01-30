# KENG's Home Manager Configuration

Nix + Home Managerによるクロスプラットフォーム開発環境設定

## セットアップ

### 事前準備

#### macOSの場合

Homebrewを先にインストールしてください。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Linuxの場合

特に事前準備は不要です（Flatpakは自動インストールされます）。

### 初回インストール

```bash
# リポジトリをクローン
mkdir -p ~/repos
git clone https://github.com/keng-oh/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles

# 初回セットアップ実行
make install
```

### 日常的な使い方

```bash
# 設定を適用
make switch

# flakeを更新して適用
make update

# 設定をチェック（適用せず）
make check

# 古い世代を削除
make clean

# ヘルプを表示
make help
```

## ディレクトリ構成

```
~/repos/dotfiles/
├── flake.nix           # Flake設定
├── home.nix            # 共通ホーム設定
├── Makefile            # セットアップ・管理用
├── modules/
│   ├── packages.nix    # パッケージリスト（CLI/開発ツール）
│   ├── git.nix         # Git設定
│   ├── zsh.nix         # Zsh設定とエイリアス
│   ├── zellij.nix      # Zellij設定
│   ├── wezterm.nix     # WezTerm設定ファイル管理
│   ├── cli-tools.nix   # CLIツール設定（Starship, direnv等）
│   ├── linux.nix       # Linux固有設定（Flatpak経由でGUIアプリ管理）
│   └── darwin.nix      # macOS固有設定（Homebrew Cask経由でGUIアプリ管理）
├── wezterm/
│   └── wezterm.lua     # WezTerm設定ファイル
└── README.md
```

## パッケージ管理

### CLI/開発ツール
Nixで宣言的に管理（再現性重視）

### GUIアプリケーション
- **Linux**: Flatpak経由で管理
  - WezTerm, Chrome, VSCode, Ulauncher
- **macOS**: Homebrew Cask経由で管理
  - WezTerm, Chrome, VSCode, Raycast

## エイリアス一覧

### Nix/Home Manager

- `hms` - 設定を適用
- `hmu` - 更新して適用

### Git

- `g` - git
- `gs` - git status
- `ga` - git add
- `gc` - git commit
- `gp` - git push
- `gl` - git pull
- `glog` - git log (グラフ表示)

### ファイル操作

- `ll` - 詳細リスト表示
- `la` - 隠しファイル含む
- `lt` - ツリー表示
- `cat` - bat (シンタックスハイライト)

### その他

- `..`, `...`, `....` - ディレクトリ移動
- `c` - clear
- `update` - システムアップデート

# KENG's Home Manager Configuration

Nix + Home Manager によるクロスプラットフォーム開発環境設定

## 対応環境

| 設定名 | 対象 | GUIアプリ管理 |
|--------|------|--------------|
| `arch` | CachyOS / Arch Linux（Hyprland） | paru |
| `ubuntu` | Ubuntu / Pop!OS | snap / apt |
| `ubuntu-server` | Ubuntu Server（GUIなし） | — |
| `mac` | macOS | Homebrew Cask |

## セットアップ

### 事前準備

#### macOS の場合

Homebrew を先にインストールしてください。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Arch / Ubuntu の場合

特に事前準備は不要です。

### 初回インストール

```bash
# ~/repos/dotfiles に clone（このパスが必須）
mkdir -p ~/repos
git clone https://github.com/keng-oh/dotfiles.git ~/repos/dotfiles

# セットアップ（OS を自動判別）
bash ~/repos/dotfiles/init.sh
```

`init.sh` は以下を自動実行します：

1. Nix のインストール
2. Flakes の有効化
3. Home Manager の適用
4. zsh をデフォルトシェルに設定

完了後、再ログインすると zsh が起動します。

### サーバー環境の場合

```bash
CONFIG=ubuntu-server bash ~/repos/dotfiles/init.sh
```

## 日常的な使い方

```bash
make switch    # 設定を適用
make update    # flake を更新して適用
make check     # 設定をチェック（適用せず）
make clean     # 古い世代を削除
```

各環境のエイリアスでも適用できます：

```bash
hms   # home-manager switch（OS に応じた設定を適用）
hmu   # make update を実行
```

## ディレクトリ構成

```
dotfiles/
├── init.sh                     # 初回セットアップスクリプト
├── Makefile                    # 日常操作用
├── flake.nix                   # Nix Flake 設定
├── common.nix                  # 全環境共通のエントリポイント
├── modules/
│   ├── common/                 # 全環境共通モジュール
│   │   ├── packages.nix        # CLI / 開発ツール
│   │   ├── git.nix             # Git 設定
│   │   ├── zsh.nix             # Zsh 設定・エイリアス
│   │   ├── cli-tools.nix       # Starship, direnv, fzf 等
│   │   ├── wezterm.nix         # WezTerm 設定ファイル管理
│   │   └── zellij.nix          # Zellij 設定ファイル管理
│   ├── arch.nix                # Arch / CachyOS 固有設定
│   ├── hyprland.nix            # Hyprland 設定（arch から読み込み）
│   ├── ubuntu.nix              # Ubuntu 固有設定
│   ├── ubuntu-server.nix       # Ubuntu Server 固有設定
│   └── darwin.nix              # macOS 固有設定
├── hypr/
│   └── hyprland.conf           # Hyprland 設定ファイル
├── wezterm/
│   └── wezterm.lua             # WezTerm 設定ファイル
└── zellij/
    └── config.kdl              # Zellij 設定ファイル
```

## インストールされるもの

### CLI / 開発ツール（全環境共通）

| カテゴリ | ツール |
|---------|--------|
| エディタ | neovim |
| シェル | zsh, starship |
| ファイル操作 | eza, bat, fd, fzf, zoxide |
| Git | git, delta, lazygit, gh |
| 検索 | ripgrep |
| 開発 | nodejs, python, direnv |
| ターミナル多重化 | zellij |
| モニタリング | htop, btop, lazydocker |
| AI | claude-code |

### GUI アプリ

| アプリ | arch | ubuntu | mac |
|--------|------|--------|-----|
| WezTerm | paru | snap | brew |
| Chrome | paru | apt | brew |
| VS Code | paru | snap | brew |
| Obsidian | paru | snap | brew |
| Discord | paru | snap | brew |
| Spotify | paru | snap | brew |
| 1Password | paru | snap | brew |
| Docker Engine | paru | apt | — |
| Ulauncher | paru | — | — |
| Raycast | — | — | brew |

### Hyprland エコシステム（arch のみ）

waybar, mako, wofi, swww, hyprlock, grimblast, wl-clipboard, brightnessctl

## キーバインド（Hyprland）

| キー | 動作 |
|------|------|
| `SUPER + Return` | WezTerm を起動 |
| `SUPER + R` | wofi（アプリランチャー） |
| `SUPER + Q` | ウィンドウを閉じる |
| `SUPER + F` | フルスクリーン |
| `SUPER + V` | フローティング切替 |
| `SUPER + H/J/K/L` | フォーカス移動 |
| `SUPER + SHIFT + H/J/K/L` | ウィンドウ移動 |
| `SUPER + ALT + H/J/K/L` | ウィンドウリサイズ |
| `SUPER + 1〜9` | ワークスペース切替 |
| `SUPER + SHIFT + 1〜9` | ウィンドウをワークスペースへ移動 |
| `SUPER + L` | スクリーンロック |
| `Print` | スクリーンショット（範囲選択） |

## エイリアス一覧

### Nix / Home Manager

| エイリアス | コマンド |
|-----------|---------|
| `hms` | `home-manager switch`（OS 別設定） |
| `hmu` | `make update` |

### Git

| エイリアス | コマンド |
|-----------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `gco` | `git checkout` |
| `glog` | `git log --oneline --graph` |

### ファイル操作

| エイリアス | コマンド |
|-----------|---------|
| `ls` | `eza` |
| `ll` | `eza -la` |
| `la` | `eza -a` |
| `lt` | `eza -T` |
| `cat` | `bat` |
| `cd` | `zoxide` |

### その他

| エイリアス | 動作 |
|-----------|------|
| `update` | システムアップデート（OS 別） |
| `..` `...` `....` | 親ディレクトリへ移動 |
| `c` | `clear` |
| `ports` | 使用中のポートを表示 |

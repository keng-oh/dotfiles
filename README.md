# KENG's Home Manager Configuration

Nix + Home Managerによるクロスプラットフォーム開発環境設定

## セットアップ

### 初回インストール

```bash
# リポジトリをクローン
mkdir -p ~/repos
git clone https://github.com/keng-oh/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles

# modules/git.nixのGitメールアドレスを確認・編集
nano modules/git.nix

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
│   ├── packages.nix    # パッケージリスト
│   ├── git.nix         # Git設定
│   ├── zsh.nix         # Zsh設定とエイリアス
│   ├── cli-tools.nix   # CLIツール設定
│   ├── linux.nix       # Linux固有設定
│   └── darwin.nix      # macOS固有設定
└── README.md
```

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

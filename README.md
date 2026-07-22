# KENG's dotfiles

chezmoi + pacman/paru による開発環境設定

対応環境: Arch Linux (CachyOS) + Hyprland

## セットアップ(新規マシン)

```bash
curl -fsSL https://raw.githubusercontent.com/keng-oh/dotfiles/master/init.sh | bash
```

`init.sh` は以下を自動実行します:

1. git / chezmoi のインストール
2. このリポジトリを `~/repos/dotfiles` にクローン
3. chezmoi のソースディレクトリ設定
4. `chezmoi apply`(パッケージ一括インストール・セットアップスクリプト・設定配置)
5. デフォルトシェルを zsh に設定

完了後、再ログインすると Hyprland セッション + zsh が有効になります。

残る手動ステップ: 1Password ログイン(SSH エージェント)、`tailscale up`、
`gh auth login`、各アプリのログイン。

## 日常的な使い方

```bash
make switch    # 設定を適用(= chezmoi apply)
make diff      # 適用される差分を確認(= chezmoi diff)
make update    # リポジトリ + パッケージ(pacman/AUR)更新
make doctor    # chezmoi の状態診断
```

エイリアス: `cza`(apply) / `czd`(diff) / `dots`(ソースディレクトリへ移動) / `update`(paru -Syu)

## ディレクトリ構成

```
dotfiles/
├── init.sh                      # 初回セットアップスクリプト
├── Makefile                     # 日常操作用
├── .chezmoiroot                 # chezmoi ソースを home/ に指定
├── home/                        # chezmoi ソース(~ に展開される)
│   ├── dot_zshrc / dot_zshenv   # zsh 設定・環境変数
│   ├── private_dot_ssh/         # SSH 設定と公開鍵(秘密鍵は 1Password)
│   ├── .chezmoiscripts/         # セットアップスクリプト(run_once / run_onchange)
│   └── dot_config/
│       ├── packages/            # パッケージリスト(pacman.txt / aur.txt)
│       ├── hypr/                # Hyprland・hypridle・電源メニュー・壁紙
│       ├── waybar/ wofi/ swaync/  # デスクトップ UI
│       ├── wezterm/ zellij/     # ターミナル
│       ├── fcitx5/              # 日本語入力
│       └── git/ gtk-3.0/ gtk-4.0/ bat/ ...
└── wallpapers/                  # 壁紙
```

## パッケージ管理

- 公式リポジトリ(CachyOS 含む)→ `home/dot_config/packages/pacman.txt`
- AUR のみ → `home/dot_config/packages/aur.txt`
- リストに追記して `make switch` すると自動でインストールされる
- Tailscale のみ公式スクリプト経由(`run_once_after_20-tailscale.sh`)

## キーバインド(Hyprland)

| キー | 動作 |
|------|------|
| `SUPER + Return` | WezTerm |
| `SUPER + R` | wofi(アプリランチャー) |
| `SUPER + B` | Chrome |
| `SUPER + Q` | ウィンドウを閉じる |
| `SUPER + F` | フルスクリーン |
| `SUPER + V` | クリップボード履歴 |
| `SUPER + H/J/K/L` | フォーカス移動 |
| `SUPER + SHIFT + H/J/K/L` | ウィンドウ移動 |
| `SUPER + ALT + H/J/K/L` | ウィンドウリサイズ |
| `SUPER + 1〜0` | ワークスペース切替 |
| `SUPER + SHIFT + 1〜0` | ウィンドウをワークスペースへ移動 |
| `SUPER + CTRL + L` | スクリーンロック |
| `Print` | スクリーンショット(範囲選択) |

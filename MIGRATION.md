# Nix/Home Manager → chezmoi 移行手順

Nix + Home Manager による管理をやめ、chezmoi + pacman/paru に移行するための手順書。
最終目標: **マシン内にNixの残骸を一切残さず**、シンプルな構成に移行する。

## 前提(2026-07 時点の調査結果)

- Nixは**シングルユーザーインストール**(`--no-daemon`)。`/nix` はkeng所有、nix-daemonサービスなし、nixbldユーザーなし
- システム側のNix痕跡は以下のみ:
  - `/nix` 本体
  - `/etc/zsh/zshrc` と `/etc/bashrc` の `# Nix ... # End Nix` ブロック
  - `/usr/share/sddm/themes/sddm-astronaut-theme`(コピーなので単体で動作する)
- ホーム側: `.nix-channels` / `.nix-defexpr` / `.nix-profile` / `~/.local/state/nix` /
  `~/.local/state/home-manager` / `~/.config/home-manager` / `.zshrc.backup` /
  多数の `/nix/store` へのシンボリックリンク(`.zshrc`, `.zshenv`, `.zprofile`, `.gtkrc-2.0`, `~/.config` 以下)
- **注意: 現在稼働中のHyprlandセッション・zsh・fcitx5はすべてNix製バイナリ。**
  `/nix` を先に消すとセッションもシェルも即死する。必ず下記の順番を守ること。

## 全体の流れ

```
Phase 0  準備(ブランチ作成・現状インベントリ・生成済み設定のエクスポート)
Phase 1  パッケージ対応表の作成(nixpkgs → pacman/AUR)
Phase 2  chezmoiリポジトリ構築(Nix稼働中に並行作業、壊れない)
Phase 3  pacman/paruで代替パッケージを一括インストール(共存、壊れない)
Phase 4  chezmoi apply でHMシンボリックリンクを実ファイルに置換
Phase 5  ログアウト → pacman版Hyprlandで再ログイン → 動作確認
Phase 6  /nix をリネームで無効化して数日運用(いつでも復旧可能)
Phase 7  完全削除・残骸掃除
```

各Phaseにロールバック手段あり。Phase 6 までは `home-manager switch` でいつでも元に戻せる。

---

## Phase 0: 準備

```sh
cd ~/repos/dotfiles
git checkout -b migrate-chezmoi
mkdir -p migration-work
```

### 0-1. HM管理ファイルのインベントリ取得

```sh
# HMが管理しているシンボリックリンクの全リスト(後で置換漏れチェックに使う)
find ~ -maxdepth 4 -lname '/nix/store/*' -not -path '*/.cache/*' \
  | tee migration-work/hm-symlinks.txt
```

### 0-2. Nixが生成した設定ファイルの実体エクスポート

HMがNix式から生成しているファイルは、`cp -L`(リンク先の実体をコピー)で回収する。

```sh
cp -L ~/.zshrc            migration-work/zshrc.generated
cp -L ~/.zshenv           migration-work/zshenv.generated
cp -L ~/.zprofile         migration-work/zprofile.generated
cp -L ~/.ssh/config       migration-work/ssh_config
cp -L ~/.gitconfig        migration-work/gitconfig
cp -L ~/.gtkrc-2.0        migration-work/gtkrc-2.0
cp -rL ~/.config/waybar   migration-work/waybar
cp -L ~/.config/gtk-3.0/settings.ini migration-work/gtk3-settings.ini
cp -L ~/.config/gtk-4.0/settings.ini migration-work/gtk4-settings.ini 2>/dev/null || true
cp -L ~/.config/bat/config migration-work/bat-config 2>/dev/null || true
# dconf(バイナリDBなのでdump)
dconf dump /org/gnome/desktop/interface/ > migration-work/dconf-interface.ini
```

生成された `.zshrc` はHM都合の記述が多いので**そのまま使わず**、
エイリアス・環境変数・プラグインsource行を参考に手書きで作り直す。

---

## Phase 1: パッケージ対応表

### 公式リポジトリ(pacman)

| nixpkgs | pacman |
|---|---|
| git / neovim / ripgrep / fd / bat / eza / fzf / jq / zoxide / zellij / htop / btop / curl / wget / tree / tldr / lazygit / navi / yazi | 同名 |
| delta | `git-delta` |
| gh | `github-cli` |
| nodejs_22 | `nodejs-lts-jod` + `npm`(または後述のmise) |
| python311 | `python`(3.13系になる点に注意) + `uv` |
| php83 | `php` |
| ruby | `ruby` |
| go | `go` |
| jdk17 | `jdk17-openjdk`(JAVA_HOME: `/usr/lib/jvm/java-17-openjdk`) |
| blueman / wtype | 同名 |
| discord | `discord` |
| obsidian | `obsidian` |
| noto-fonts-cjk-* | `noto-fonts-cjk` |
| gnome-keyring / libsecret / gcr | 同名(gnome-keyringは既にparu導入済み) |
| hyprland / hyprlock / hypridle / waybar / wofi / wl-clipboard / cliphist / brightnessctl / playerctl / polkit-gnome / papirus-icon-theme | 同名(polkit-gnomeはAURの場合あり) |
| networkmanagerapplet | `network-manager-applet` |
| swaynotificationcenter | `swaync` |
| awww (旧swww) | `swww` |
| adw-gtk3 | `adw-gtk-theme` |
| fcitx5 + fcitx5-mozc + fcitx5-gtk | `fcitx5-im`(グループ) + `fcitx5-mozc` |
| zsh統合系 | `zsh` `zsh-syntax-highlighting` `zsh-autosuggestions` `starship` `direnv` |

### AUR(paru)— 既存のparu管理分に追加

| nixpkgs | AUR |
|---|---|
| vscode | `visual-studio-code-bin` |
| spotify | `spotify` |
| _1password-gui | `1password` |
| sddm-astronaut | `sddm-astronaut-theme` |
| grimblast | `grimblast-git` |
| lazydocker | `lazydocker` |
| doppler | `doppler-cli-bin` |
| claude-code | `claude-code` |
| flutter | `flutter`(重いのでバイナリ版 `flutter-bin` も検討) |

既存paru管理分(google-chrome, wezterm-git, ttf-hackgen, xdg-desktop-portal-hyprland,
docker, docker-compose, claude-desktop, gnome-keyring, android-sdk-*, android-emulator, android-udev)はそのまま。

> パッケージ名は移行時に `paru -Si <名前>` で実在確認すること。

---

## Phase 2: chezmoiリポジトリ構築

Nixが動いている間に、壊さず並行して作業できる。

**このリポジトリ(`~/repos/dotfiles`)をそのままchezmoiのソースとして使う。**
chezmoiのデフォルトソースは `~/.local/share/chezmoi` だが、設定ファイルで変更できる。
リポジトリの場所・リモート(github.com/keng-oh/dotfiles)・履歴はすべてそのまま。

```sh
paru -S --needed chezmoi

# ソースディレクトリを恒久設定(これで --source フラグ不要になる)
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
sourceDir = "~/repos/dotfiles"
EOF
```

以降 `chezmoi cd` は `~/repos/dotfiles` に移動し、`chezmoi apply` もここを読む。
git操作は今までどおり普通にこのリポジトリで行えばよい
(`chezmoi update` のようなchezmoi経由のgit操作も同じリポジトリを触る)。

### 2-1. ディレクトリ構成(このリポジトリ内に `home/` を作る)

```
dotfiles/
├── home/                              # chezmoiソースディレクトリ
│   ├── dot_zshrc                      # 手書きで再構成(Phase 0のexport参照)
│   ├── dot_zshenv                     # 環境変数・PATH(ANDROID_HOME, JAVA_HOME等)
│   ├── dot_gitconfig
│   ├── dot_gtkrc-2.0
│   ├── private_dot_ssh/config         # ssh.nixの内容を書き下し
│   ├── dot_config/
│   │   ├── hypr/                      # 既存 hypr/ を移動(powermenu.sh含む)
│   │   ├── waybar/                    # Phase 0でエクスポートしたもの
│   │   ├── wofi/  swaync/  wezterm/  zellij/   # 既存ディレクトリを移動
│   │   ├── fcitx5/                    # chezmoiはコピー方式なのでそのまま置ける
│   │   ├── gtk-3.0/settings.ini
│   │   ├── gtk-4.0/settings.ini
│   │   └── starship.toml / bat/config など
│   ├── run_onchange_install-packages.sh.tmpl   # パッケージリスト変更時に実行
│   ├── run_once_before_00-multilib.sh          # multilib有効化
│   ├── run_once_10-tailscale.sh
│   ├── run_once_20-docker.sh                   # enable + usermod -aG docker
│   ├── run_once_30-android-sdk.sh              # ライセンス同意・AVD作成・adbusers
│   ├── run_once_40-sddm-theme.sh
│   └── run_onchange_50-dconf.sh.tmpl           # dconf load(ファイル配置では反映不可)
├── packages/
│   ├── pacman.txt                     # 公式リポジトリのパッケージリスト
│   └── aur.txt                        # AURパッケージリスト
├── .chezmoiroot                       # 中身: home
└── Makefile                           # chezmoi用に書き換え
```

ポイント:

- **`.chezmoiroot`** に `home` と書くと、リポジトリ直下ではなく `home/` がソースになる
  (移行中はNixファイルと共存できる)
- **`run_onchange_install-packages.sh.tmpl`** の中にパッケージリストのハッシュを
  埋め込むと、リスト変更時だけ再実行される:

  ```sh
  #!/bin/bash
  # pacman.txt hash: {{ include "../packages/pacman.txt" | sha256sum }}
  # aur.txt hash: {{ include "../packages/aur.txt" | sha256sum }}
  set -euo pipefail
  cd "$(chezmoi source-path)/.."
  sudo pacman -S --needed --noconfirm - < packages/pacman.txt
  paru -S --needed - < packages/aur.txt
  ```

- `run_once_*` の中身は現行 `modules/arch.nix` の `home.activation` ブロックと
  `common.nix` のtailscaleSetupをほぼコピペで移植できる
- fcitx5はchezmoi標準がコピー方式なので、現行の「コピー適用ワークアラウンド」は不要になる

### 2-2. 初期化と検証(まだapplyしない)

```sh
chezmoi init --source ~/repos/dotfiles
chezmoi diff        # 何が変わるか確認。apply はまだしない
```

---

## Phase 3: 代替パッケージの一括インストール

Nixとpacmanのバイナリは共存できる(PATHの優先順位が変わるだけ)。ここでは何も壊れない。

```sh
sudo pacman -S --needed - < packages/pacman.txt
paru -S --needed - < packages/aur.txt
```

確認:

```sh
# 主要コマンドがpacman側(/usr/bin)にも存在するか
for c in zsh hyprland waybar wofi fcitx5 git nvim starship zellij; do
  ls /usr/bin/$c >/dev/null 2>&1 && echo "OK $c" || echo "MISSING $c"
done
```

---

## Phase 4: chezmoi apply

```sh
chezmoi diff     # 最終確認
chezmoi apply -v # HMのシンボリックリンクが実ファイルで上書きされる
```

確認:

```sh
# .zshrc等が実ファイルになったか(シンボリックリンクでないこと)
ls -la ~/.zshrc ~/.zshenv ~/.ssh/config

# 新しいターミナルを開いてzshが正常起動するか
# エイリアス・starship・zoxide・fzf・direnvが効くか確認
```

この時点ではPATHにまだ `~/.nix-profile/bin` が入っていてもよい。
新しい `.zshenv` / `.zshrc` にはNix関連のPATH追記を**入れない**こと。

ロールバック: `home-manager switch --impure --flake ~/repos/dotfiles#arch` で全て元に戻る。

---

## Phase 5: セッション切替と動作確認

ログアウト → SDDMから再ログイン(pacman版Hyprlandが起動する)。

チェックリスト:

- [ ] Hyprland起動、キーバインド動作
- [ ] waybar表示(ワークスペース・時計・音量・ネットワーク・通知・電源メニュー)
- [ ] fcitx5で日本語入力(wezterm・Chrome両方で)
- [ ] swaync通知センター
- [ ] スクリーンショット(grimblast)、クリップボード履歴(cliphist)
- [ ] hyprlockロック、hypridle
- [ ] GTK/Qtダークテーマ、アイコン、カーソル
- [ ] 壁紙(swww)
- [ ] 1Password SSHエージェント(`ssh -T git@github.com`)
- [ ] docker(`docker ps`)
- [ ] adb / emulator(`adb devices`, AVD起動)
- [ ] wezterm / zellij / neovim / lazygit
- [ ] `which zsh hyprland waybar` が `/usr/bin` を指すこと

---

## Phase 6: Nix無効化テスト(削除前の安全確認)

**いきなり消さず、リネームで無効化して数日運用する。**

```sh
sudo mv /nix /nix.disabled
```

再起動して通常どおり使う。壊れたものがあれば
`sudo mv /nix.disabled /nix` で即復旧できる。

数日問題なければ、`find ~ -xtype l | grep -v .cache` でリンク切れ
(=置換漏れのHMファイル)がないか最終確認。あれば chezmoi 側に追加する。

---

## Phase 7: 完全削除・残骸掃除

```sh
# 1. /nix 本体
sudo rm -rf /nix.disabled

# 2. /etc のシェルフック(「# Nix」〜「# End Nix」のブロックを削除)
sudo sed -i '/^# Nix$/,/^# End Nix$/d' /etc/zsh/zshrc /etc/bashrc

# 3. ホームの残骸
rm -rf ~/.nix-channels ~/.nix-defexpr ~/.nix-profile \
       ~/.local/state/nix ~/.local/state/home-manager \
       ~/.config/home-manager ~/.zshrc.backup

# 4. リンク切れの最終掃除
find ~ -xtype l -not -path '*/.cache/*'   # 出たものを個別に確認して削除

# 5. systemd userユニットの残骸確認(HMが置いた壊れたユニットがないか)
systemctl --user list-units --state=failed
ls -la ~/.config/systemd/user/ 2>/dev/null
```

### リポジトリの後始末

- `flake.nix` / `flake.lock` / `common.nix` / `modules/` を削除
- `Makefile` をchezmoi用に書き換え(`make switch` → `chezmoi apply` 等)
- `.claude/CLAUDE.md` を新構成に合わせて更新
- `.github/workflows/check.yml` を削除またはchezmoi構成の検証用に書き換え
  (現在はGitHub上で手動停止中: 再開は `gh workflow enable "Check"`)
- `MIGRATION.md`(このファイル)と `migration-work/` を削除
- `migrate-chezmoi` ブランチをmasterにマージ

---

## 新規マシン(CachyOS再インストール直後)での復元手順

このリポジトリはパブリックなので、認証なしでクローンして始められる。
CachyOSはparuが標準搭載されている前提。

```sh
# 1. ブートストラップ(この3行だけ。init.shにまとめてもよい)
sudo pacman -S --needed git chezmoi
git clone https://github.com/keng-oh/dotfiles ~/repos/dotfiles
mkdir -p ~/.config/chezmoi && printf 'sourceDir = "~/repos/dotfiles"\n' > ~/.config/chezmoi/chezmoi.toml

# 2. 適用(パッケージ一括インストール・run_once群・設定配置がすべて走る)
chezmoi apply

# 3. 再ログイン(Hyprlandセッション・zsh・fcitx5が有効になる)
```

`run_once_*` スクリプトは「新規マシンで初回だけ実行」がまさに本来の用途なので、
multilib有効化 → パッケージ導入 → tailscale/docker/android-sdk/sddmテーマ/dconf が自動で流れる。

### 自動で復元されないもの(手動ステップ)

- **CachyOSインストーラでの選択**: SDDMと(仮の)デスクトップ環境はインストーラ任せ。
  最小構成で入れてもchezmoiがhyprland等を入れるので問題ない
- **1Passwordへのログイン** — これをするまでSSHエージェントが動かない。
  git push(SSHリモート)はログイン後に
- **各サービスの認証**: `tailscale up` / `gh auth login` / doppler / ブラウザ・Spotify・Discord等のログイン
- **データ**: `~/repos` 以下のプロジェクト、Obsidian vault、ブラウザプロファイル、
  dockerボリューム等は設定管理の対象外。別途バックアップが必要

### 復元性を上げるためにPhase 2でやっておくこと

- **`~/.ssh/*.pub` をchezmoi管理に入れる**(`private_dot_ssh/` 以下)。
  ssh configが `github.pub` / `proxmox.pub` / `proxmox_dev.pub` を参照しているが、
  現在リポジトリに入っていない。1Password運用なので秘密鍵はマシンに存在せず、
  .pubさえリポジトリにあれば鍵まわりは完全復元できる
- 上記ブートストラップ3行を `init.sh` としてリポジトリ直下に置き、
  `curl -fsSL https://raw.githubusercontent.com/keng-oh/dotfiles/master/init.sh | bash`
  の一発で入るようにする

---

## 失うもの(了承済みの前提)

- flake.lockによる全ツールのバージョン固定・環境の完全再現性
- mac / ubuntu / ubuntu-server ターゲット(必要になったらchezmoiのテンプレート機能で
  OS分岐を書く。`{{ .chezmoi.os }}` で判定可能)
- `nix flake check` による構文チェック(chezmoiには `chezmoi diff` / `chezmoi verify` がある)

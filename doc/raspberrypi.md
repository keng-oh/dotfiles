# Raspberry Pi メモ

Raspberry Pi 上の Debian に dotfiles を展開するときの覚え書き。
(調査日: 2026-08-26 / ホスト `rpi-home`)

## 環境

```
Debian GNU/Linux 13 (trixie)   # /etc/os-release の ID=debian, VERSION_CODENAME=trixie
arm64                          # dpkg --print-architecture
```

Raspberry Pi OS ではなく素の Debian 13。有効なリポジトリ:

| リポジトリ | Suites | Components |
|---|---|---|
| deb.debian.org/debian | trixie, trixie-updates | main contrib non-free non-free-firmware |
| deb.debian.org/debian-security | trixie-security | 同上 |
| archive.raspberrypi.com/debian | trixie | main |
| pkgs.tailscale.com/stable/debian | trixie | main |
| deb.nodesource.com/node_22.x | nodistro | main (arm64) |

## dotfiles がこの環境でどう動くか

chezmoi のテンプレートは `.chezmoi.osRelease.id` が `cachyos` かどうかで分岐する。
Pi では `debian` なので **非CachyOS 側**の挙動になる。

- パッケージ導入: [`run_onchange_before_10-packages.sh.tmpl`](../home/.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl)
  の apt 分岐が走り、[`apt.txt`](../home/dot_config/packages/apt.txt) だけがインストールされる
  (`pacman.txt` / `aur.txt` は無視される)。加えて starship を公式スクリプトで導入。
- 配置されないもの: [`.chezmoiignore`](../home/.chezmoiignore) で除外
  (hypr / waybar / wofi / swaync / fcitx5 / gtk / wezterm / environment.d / `.ssh` /
  Arch 専用セットアップスクリプト)。
- 配置されるもの: `.zshrc` `.zshenv`、`.config/zellij`、`.config/git`、`.config/bat`、
  `.config/packages` など除外リストに無いもの全部。

`.zshrc` は zsh プラグイン・fzf・eza / bat / fd のバイナリ名・`update` エイリアスを
Arch / Debian 両対応で書いてあるので、そのままで動く。
`.zshenv` は [`dot_zshenv.tmpl`](../home/dot_zshenv.tmpl) でテンプレート化してあり、
Pi には `LANG` しか配置されない(fcitx5 / Android SDK / Chrome は CachyOS 専用)。

## apt で入るもの / 入らないもの

trixie で確認した結果:

| パッケージ | apt | 備考 |
|---|---|---|
| zellij | ✗ | Debian 未収載。手動導入(下記) |
| claude-code | ✗ | Debian 未収載。手動導入(下記) |
| eza | ✓ 0.21.0 | apt.txt には未収載 |
| lazygit | ✓ 0.50.0 | apt.txt には未収載 |
| git-delta | ✓ 0.18.2 | apt.txt には未収載 |
| starship | ✓ 1.22.1 | apt.txt には未収載(公式スクリプトで導入している) |
| zoxide / bat / ripgrep / fd-find | ✓ | apt.txt 収載済み |

`apt.txt` 冒頭のコメントは Ubuntu 基準で「eza / zellij / lazygit / delta は無い」と
書いてあるが、**trixie では zellij 以外は apt で入る**。

apt.txt に追記していないのは、インストール処理が
`grep ... | xargs apt-get install -y` で **1つでも存在しないパッケージがあると全体が失敗する**ため。
Ubuntu サーバーでも同じリストを使う想定なら、先に
「存在するものだけ入れる」方式に変えてから追記すること。

## 手動導入

方針: **実体は `~/.local/bin` に置き、`/usr/local/bin` からシンボリックリンクを張る**。

`~/.local/bin` は PATH に入っていない(後述)が、`/usr/local/bin` は最初から入っている。
実体を `/usr/local/bin` に直接置くと root 所有になり、ユーザー権限の自動更新が失敗する。
リンク方式ならリンク先のパスは更新後も変わらないので壊れない。

### zellij

設定 `~/.config/zellij/config.kdl` は配置されるが、バイナリは入らない。

```bash
mkdir -p ~/.local/bin
curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-unknown-linux-musl.tar.gz \
  | tar xz -C ~/.local/bin
sudo ln -s ~/.local/bin/zellij /usr/local/bin/zellij
```

更新は同じ curl を叩き直すだけ(リンクはそのままでよい)。

### Claude Code

CachyOS では `pacman.txt` の `claude-code` で入るが、Debian には相当パッケージが無い。

```bash
# 公式インストーラ(推奨。~/.local/bin/claude に入り自動更新も効く)
curl -fsSL https://claude.ai/install.sh | bash
sudo ln -s ~/.local/bin/claude /usr/local/bin/claude
```

npm 経由(`npm install -g @anthropic-ai/claude-code`)でも入るが、
この場合は nodesource の Node 22 側に入るのでリンクは不要。

## ハマりどころ

### 1. apt の出力が日本語になる

[`dot_zshenv.tmpl`](../home/dot_zshenv.tmpl) で `LANG=ja_JP.UTF-8` を export しているため、
`apt-cache policy` は `Candidate:` ではなく `候補:` を出力する。
grep / awk するときは `LC_ALL=C` を付ける。

(以前は `LC_ALL` も export していたが、`LC_ALL` は全ての `LC_*` を上書きして
個別指定を効かなくするため削除済み。`LC_MESSAGES=C` でも同じことができる)

```bash
# パッケージが入るか確認
LC_ALL=C apt-cache policy <pkg>          # Candidate: にバージョンが出れば導入可能

# 複数まとめて確認
for p in zellij eza lazygit git-delta starship; do
  printf '%-12s %s\n' "$p" "$(LC_ALL=C apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2}')"
done
```

その他の確認コマンド:

```bash
LC_ALL=C apt list -a <pkg>        # 全リポジトリの候補一覧
LC_ALL=C apt-cache madison <pkg>  # バージョンと提供元
apt-get install -s <pkg>          # 実際には入れずにシミュレート(sudo 不要)
```

### 2. `~/.local/bin` は PATH に入っていない

[`dot_zshenv.tmpl`](../home/dot_zshenv.tmpl) は `~/.local/bin` を PATH に追加していない。
Debian でこれを追加しているのは `~/.profile` だが、zsh はそれを読まないため効かない。
実際の PATH:

```
/usr/local/bin : /usr/bin : /bin : /usr/games
```

**PATH はいじらない方針**。手動導入したバイナリは `/usr/local/bin` から
シンボリックリンクを張って通す(「手動導入」参照)。

```bash
echo $PATH | tr ':' '\n' | grep local/bin   # 確認用
```

### 3. Arch 専用の環境変数(対応済み)

以前は `dot_zshenv` が fcitx5 / Android SDK / Chrome のパスを無条件に export していた。
特に `JAVA_HOME=/usr/lib/jvm/java-17-openjdk` は Arch 固有のパスで、
Debian の JDK は `/usr/lib/jvm/java-17-openjdk-arm64` のため、
Pi に JDK を入れると存在しないパスを指す `JAVA_HOME` で gradle / maven が壊れる。

現在は [`dot_zshenv.tmpl`](../home/dot_zshenv.tmpl) で CachyOS 専用ブロックに分離済み。
Pi 側に配置されるのは `LANG` だけ。JDK を入れるときは `JAVA_HOME` が
未設定であることを確認すること(必要なら Debian のパスで別途設定する)。

### 4. yazi が入らない

[`dot_zshrc`](../home/dot_zshrc) の `yy` 関数は yazi を呼ぶが、apt.txt に yazi は無い。
呼ばなければ害は無い。使いたければ別途導入が必要。

# Proxmox VE サーバーメモ

Proxmox VE ホストに dotfiles を展開するときの覚え書き。
(調査日: 2026-09-14 / ホスト `pve01`)

自宅サーバーとして常時稼働している一台。デスクトップ用途は無く、
LXC コンテナ群を載せるハイパーバイザとして使っている。
**その上で何が動いているかはこのリポジトリの管轄外**なので、
サービス構成は別途 private なノートリポジトリ側で管理している。

## 環境

```
Debian GNU/Linux 12 (bookworm)   # /etc/os-release の ID=debian
Proxmox VE 8.4.18                # pveversion
amd64 / kernel 6.8.12-20-pve     # PVE の独自カーネル
```

Proxmox VE は Debian の上に構築されているため、chezmoi から見れば
`.chezmoi.osRelease.id` は `debian`。**非CachyOS 側**の挙動になる。

## このマシン固有の前提

### root が正規の管理者

Proxmox VE は root で運用するのが正規の形で、**初期状態では sudo が入っていない**。
`.zshrc` の `update` エイリアスをはじめ、スクリプトの多くが `sudo` を前提に
書かれているため、[`init.sh`](../init.sh) の冒頭で sudo が無ければ導入する。
`apt.txt` にも `sudo` を入れて、以降 apt 更新で消えないようにしてある。

分岐を各スクリプトに持たせず入口で揃える方針なので、
**新しいスクリプトに「sudo があるか」の判定を足さないこと**。

例外は Claude Code の公式インストーラで、`$HOME` 配下に入れる作りのため
sudo を付けてはいけない。

### chezmoi のソースは root のホーム配下

```
sourceDir = /root/repos/dotfiles/home
username  = root
hostname  = pve01
```

## dotfiles がこの環境でどう動くか

- パッケージ導入: [`run_onchange_before_10-packages.sh.tmpl`](../home/.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl)
  の apt 分岐が走り、[`apt.txt`](../home/dot_config/packages/apt.txt) だけが入る
  (`pacman.txt` / `aur.txt` は無視される)。加えて starship と Claude Code を
  公式スクリプトで導入し、`ja_JP.UTF-8` ロケールが無ければ生成する
- apt に無いツールは mise: [`run_onchange_after_21-mise.sh.tmpl`](../home/.chezmoiscripts/run_onchange_after_21-mise.sh.tmpl)
  が [`mise/config.toml`](../home/dot_config/mise/config.toml) を適用する
  (eza / zellij / lazygit / lazydocker / delta / navi / yazi と node / go / ruby / php)
- 配置されないもの: [`.chezmoiignore`](../home/.chezmoiignore) の非CachyOS ブロックで除外
  (hypr / waybar / wofi / swaync / fcitx5 / gtk / wezterm / environment.d /
  `.ssh` / ntfy / rclone / Arch 専用セットアップスクリプト)
- `.zshenv` に配置されるのは `LANG` と PATH 追加 (`~/.local/bin` と mise shims) のみ。
  fcitx5 / Android SDK / Chrome は CachyOS 専用ブロックの中

### `.ssh` が配置されないことに意味がある

`.chezmoiignore` は非 CachyOS に対して `.ssh/**` を除外する。
このリポジトリの [`private_dot_ssh/config`](../home/private_dot_ssh/config) は
1Password の SSH エージェント (`IdentityAgent ~/.1password/agent.sock`) を前提に
書かれているが、**このマシンに 1Password は入っていない**。

そのため `~/.ssh/config` はここでは chezmoi 管理外で、ファイルベースの鍵を直接指す
内容を手で置いてある。**管理漏れではないので dotfiles 側に取り込まないこと。**
取り込むと 1Password を参照しに行って SSH 認証が壊れる。

## ハマりどころ

### 1. エージェントが叩くシェルでも `.zshrc` が読まれ、`cd` が失敗する

[`dot_zshrc`](../home/dot_zshrc) は `cd` を zoxide の `z` にエイリアスしている
(`alias cd="z"`)。このエイリアスは zoxide の初期化と対で機能するため、
**非対話でコマンドを流し込む文脈では `_z_cd: command not found` で落ちる**ことがある。

```bash
cd /path/to/dir && git status    # 失敗しうる
git -C /path/to/dir status       # 常に動く
```

コマンドは絶対パスで書くか、`git -C` のようにディレクトリ指定のオプションを使う。
同様に `ls` → `eza`、`cat` → `bat`、`find` → `bfs` のエイリアスがあるため、
厳密な出力やパイプ処理が要るときは `command cat` のように実体を呼ぶ。

### 2. 出力が日本語になる

`.zshenv` が `LANG=ja_JP.UTF-8` を export するので、apt などの出力が日本語になる。
grep / awk でパターンマッチさせるときは `LC_ALL=C` を付ける。

```bash
LC_ALL=C apt-cache policy <pkg>
```

(`LC_ALL` 自体は export していない。全ての `LC_*` を上書きして個別指定を
効かなくするため。詳細は [`dot_zshenv.tmpl`](../home/dot_zshenv.tmpl) のコメント)

### 3. `make update` は使えない

[`Makefile`](../Makefile) の `update` ターゲットは paru 前提なので CachyOS 専用。
このマシンでは `.zshrc` の `update` エイリアス
(`sudo apt update && sudo apt upgrade`) を使う。

ただし **Proxmox ホストのパッケージ更新は影響範囲が大きい**ので、
稼働中のコンテナがある状態で無造作に流さないこと。

### 4. PVE 独自カーネルを使っている

`uname -r` が `-pve` 付きのカーネルを返す。Debian 標準のカーネルではないため、
カーネルモジュールやヘッダに依存する処理を入れるときは注意する。
`doc/system-changes/` に記録すべき類の変更 (bootloader、`/etc/sysctl.d` など) は、
このマシンでは特に慎重に扱う。

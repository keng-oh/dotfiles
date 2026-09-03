# dotfiles プロジェクト

chezmoi によるマルチ環境の開発環境設定リポジトリ。
(以前は Nix + Home Manager 管理。移行中の手順は `MIGRATION.md` 参照)

**単一OSを前提にしないこと。** 詳細は「実行環境の前提」を参照。

**このリポジトリは公開されている。** 詳細は「公開リポジトリである前提」を参照。

## 公開リポジトリである前提

このリポジトリは GitHub 上の **PUBLIC リポジトリ** (`keng-oh/dotfiles`)。
コミットした内容は全世界から見え、`git push` した後は履歴に永久に残る
(後から削除してもフォークやキャッシュからは消えない)。

### 絶対にコミットしないもの

秘密鍵、APIトークン、パスワード、`.env`、認証情報を含む設定ファイル。
秘密鍵は 1Password に置き、マシン上にもリポジトリにも存在させない。

### コミット前にユーザーへ確認するもの

**秘密ではないが、公開する必要もない識別子**。判断はユーザーのものなので、
勝手に入れず、何がどう露出するかを説明した上で確認する:

- ホスト名・IPアドレス・Tailscale の tailnet ID や MagicDNS 名
- ユーザー名、マシンのシリアル番号やサービスタグ
- `chrome://gpu` や `journalctl` などの生ダンプ(意図しない情報が紛れ込みやすい)

### 現時点で公開済みのもの(既に決定済み。蒸し返さない)

- `private_dot_ssh/*.pub` — 公開鍵。秘密ではないので意図的にコミットしている
- プライベートIP (`192.168.x.x`)、Tailscale の MagicDNS 名と IP、
  SSH のユーザー名 (`root` / `dev` / `pi-user`)

### push は別の行為

コミットはローカルに留まる。**公開が発生するのは `push` の時点**。
ユーザーが明示的に push を求めていない限り push しない。
識別子を含む変更をコミットしたときは、push 前にその旨を伝える。

## 作業上の前提

- **`sudo` が要る作業はユーザーが実行する。** アシスタントは sudo を実行できない。
  コマンドを提示してユーザーに叩いてもらい、結果を受け取って進める
- **`chezmoi apply` は 1Password に依存する。** `dot_config/ntfy/client.yml.tmpl` と
  `dot_config/rclone/create_private_rclone.conf.tmpl` が `op` を引くため、
  1Password が起動・アンロックされていないと引数なしの apply は全体が失敗する。
  特定のパスだけ反映したいときは `chezmoi apply ~/.ssh` のようにパスを指定すると、
  無関係なテンプレートを避けられる
- 反映の検証は、できる限り root 権限の要らない方法で行う
  (`cat /proc/cmdline`、ファイルの mtime など)

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
- `doc/` - メモ・調査記録
  - `system-changes/` - リポジトリ外の変更台帳(1変更1ファイル)
  - `templates/` - 台帳エントリ・調査メモのテンプレート
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

## 実行環境の前提

このリポジトリは**複数のOSに配布される**。Arch Linux (CachyOS) のデスクトップだけでなく、
Ubuntu / Pop!_OS、Raspberry Pi OS、macOS などが対象になりうる。

**特定のOSを前提にしたコードを書かないこと。** 具体的には:

- `pacman` / `paru` / `apt` などのパッケージマネージャ
- `systemctl` / `systemd-tmpfiles` / `/etc/sysctl.d`(systemd 前提。macOS には無い)
- `/opt` や `/usr/share` などのパス
- Hyprland・SDDM・fcitx5 などデスクトップ固有のコンポーネント

これらを使う場合は、必ず分岐するか、対象外の環境では配布されないようにする。

### 分岐の仕組み

| 手段 | 用途 |
|---|---|
| `.chezmoiignore`(テンプレート) | そもそもファイルを配置しない。デスクトップ専用の設定はこれで除外 |
| `{{ if eq .chezmoi.osRelease.id "cachyos" }}` | `.tmpl` 内での条件分岐 |
| `command -v <cmd> >/dev/null` | スクリプト内でコマンドの有無を確認してから使う |

現状の分岐は **「cachyos」か「それ以外」** の2分岐しかない。
`.chezmoiignore` は非 cachyos に対してデスクトップUI・`.ssh`・Arch専用スクリプトを除外し、
`run_onchange_before_10-packages.sh.tmpl` は cachyos なら pacman/paru、
それ以外は apt を使う。

### 既知の制約

- **`else` が apt 決め打ち。** Fedora など apt を持たない Linux では失敗する
- **macOS は未対応。** `.chezmoi.osRelease` は `/etc/os-release` 由来で Linux にしか存在しない。
  macOS では `.chezmoi.osRelease.id` の評価がエラーになる。対応するなら
  `{{ if eq .chezmoi.os "darwin" }}` を先に判定する形へ組み替える必要がある
- 環境を増やすときは `.chezmoiignore` と `10-packages` の両方を更新すること。
  片方だけだと、配置されない設定を参照するスクリプトが走るなどの齟齬が出る


## 編集時の注意

- 設定ファイルの編集は `home/` 以下のソースを直接編集し、`chezmoi apply` で反映
- パッケージ追加は対象OSのリストに追記する(下記「実行環境の前提」参照)
  - Arch系: `pacman.txt`(公式)/ `aur.txt`(AUR)
  - Debian系: `apt.txt`
  - リスト変更時は apply で自動インストールされる(`run_onchange_before_10-packages.sh.tmpl`)
  - 追加前に実在確認すること(`paru -Si <名前>` / `apt-cache show <名前>`)
- `home/` 内のファイル名はchezmoi規約(`dot_` = `.`、`executable_` = 実行可能、
  `private_` = パーミッション制限)
- 適用前に `chezmoi diff` で差分確認するのが安全

## リポジトリ外の変更は必ず記録する

chezmoi で管理できない場所(`/etc/` 配下、bootloader設定、systemdのシステムユニット、
ファームウェア設定など)を変更したら、**`doc/system-changes/` に必ず記録を追加する**。

理由: これらの変更はリポジトリに痕跡が残らないため、記録しないと
「いつ・何を・なぜ変えたか」が完全に失われる。数日後に自分が見ても、
別のセッションのアシスタントが見ても、経緯を再現できなくなる。

`doc/templates/system-change.md` をコピーし、`YYYY-MM-DD-<対象>.md` として作成する。
運用の詳細は `doc/system-changes/README.md` を参照。記載する内容:

- 日時 / 対象 / 状態(適用済み・適用待ち・撤去済み)
- 実際に書き込んだ値やコマンド
- **理由** — 将来その判断を再現できる程度に
- 元に戻す方法
- 検証方法(できる限り root 権限なしで確認できるもの)

撤去した変更もエントリは消さず、状態を「撤去済み」に変えて残す。
試して駄目だった記録には、同じ道を再び辿らせない価値がある。

調査が長期化する案件は、`doc/templates/investigation.md` を使って `doc/` 直下に
個別のメモを作る(例: `doc/xps-crash-2026-08.md`)。台帳とは重複させず、参照させる。


## パッケージ管理の方針

- Arch系: 公式リポジトリ(CachyOS含む)にあるものは `pacman.txt`、AURのみは `aur.txt`
- Debian系: `apt.txt`。標準リポジトリに無いものは公式スクリプト
  (starship がこの例。`run_onchange_before_10-packages.sh.tmpl` 内で処理)
- Tailscaleのみ公式インストールスクリプト経由(`run_once_after_20-tailscale.sh`)
- Android SDKは `/opt/android-sdk` にAURパッケージで配置し、
  初期化は `run_once_after_40-android-sdk.sh` が行う

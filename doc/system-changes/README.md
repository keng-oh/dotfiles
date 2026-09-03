# システム変更ログ(リポジトリ管理外)

chezmoi で管理できない場所への変更を、1変更につき1ファイルで記録する。

`/etc/` 配下・bootloader設定・systemdのシステムユニット・ファームウェア設定などは、
そのままでは**どこにも痕跡が残らず、次に触るときに理由も経緯も失われる**。
このディレクトリがその記録を担う。

## 追記のしかた

1. `../templates/system-change.md` をコピーする
2. `YYYY-MM-DD-<対象を表す短い名前>.md` にリネームする
   (例: `2026-08-28-journald-sync.md`)
3. テンプレート内のHTMLコメントの指示に従って埋め、コメント自体は削除する
4. 下の索引に1行追加する

撤去した変更もファイルは消さず、**状態を「撤去済み」に変えて残す**。
試して駄目だった記録には、同じ道を再び辿らせない価値がある。

調査が長期化する案件は `doc/` 直下に個別のメモを作る
(`../templates/investigation.md` を使う)。こちらとは重複させず、参照させる。

## 索引

新しいものが上。

| 日時 | 対象 | 内容 | 状態 |
|---|---|---|---|
| 2026-08-29 18:17 | [BIOS 1.3.1 → 1.8.2](2026-08-29-bios-1.8.2.md) | Dell システムファームウェア更新(fwupd/LVFS) | 適用済み |
| 2026-08-29 17:51 | [`/etc/sysctl.d/99-hardlockup.conf`](2026-08-29-sysctl-hardlockup.md) | ハードロックアップ検知の有効化 | 適用済み(有効) |
| 2026-08-28 16:35 | [`/etc/systemd/journald.conf.d/99-sync.conf`](2026-08-28-journald-sync.md) | `SyncIntervalSec=1s` | 適用済み(有効) |
| 2026-08-28 15:56 | [`/etc/default/grub`](2026-08-28-grub-diagnostics.md) | pstore有効化 + `nowatchdog` 撤去 + `panic=20` | 適用済み(`hardlockup_panic=1` は無効のため8/29撤去) |
| 2026-08-25 23:31 | [`/etc/default/grub`](2026-08-25-grub-xe-psr.md) | `xe.enable_psr=0` | **撤去済み(効果なし)** |

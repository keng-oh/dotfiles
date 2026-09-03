# XPS 14 ハードロックアップ調査メモ (2026-08)

Dell XPS 14 DA14260 (CachyOS) が使用中に突然フリーズする問題の調査記録。
**未解決**。セッションをまたいで作業を引き継ぐための記録。

## 症状

動画再生中に画面が固まり、音声が最後のバッファをループ(「うびびび」)して
一切の操作を受け付けなくなる。電源ボタン長押しでの強制終了しか手段がない。

音声がループするのは、オーディオDMAにデータを供給するカーネルが停止しているため。
Hyprlandだけが落ちた場合は音は普通に鳴り続けるので、**カーネルごと止まる
ハードロックアップ**と判断している。

## クラッシュ記録

| 日時 | 稼働時間 | 備考 |
|---|---|---|
| 2026-08-25 14:28 | 3時間20分 | 初回。動画再生中 |
| 2026-08-27 14:43頃 | 3分 | このブートのジャーナルは残っていない |
| 2026-08-27 16:09 | 1時間27分 | |
| 2026-08-28 15:43 | 1時間30分 | |
| 2026-08-29 17:05 | 2時間08分 | 動画再生中・**離席中**。`SyncIntervalSec=1s` 有効下でも痕跡なし |

一方で10〜15時間連続稼働して正常終了するセッションもあり、常時再現はしない。

不正終了の裏付けは毎回同じ:
- `BTRFS info: start tree-log replay`
- `systemd-journald: File ... corrupted or uncleanly shut down, renaming and replacing`

## 環境

| 項目 | 値 |
|---|---|
| 機種 | Dell XPS 14 DA14260 / BIOS **1.8.2 (2026-05-22)**(8/29に1.3.1から更新) |
| CPU | Intel Core Ultra X7 358H (Panther Lake) |
| GPU | Intel Xe3 iGPU、`xe` ドライバ、GuC 70.72.1 / HuC 10.3.3 |
| カーネル | linux-cachyos 7.2.0-1 (LTS 6.18.42 も導入済み) |
| WiFi | Intel Wi-Fi 7 BE211、`iwlmld` op_mode |
| 周辺 | Belkin TB5 Dock (Thunderbolt) |

きっかけと疑われる更新は 2026-08-23 12:40 の一括更新。
同一トランザクションで **mesa 26.1.6 → 26.2.1** と
**linux-cachyos 7.1.8 → 7.2.0** が同時に上がっている。初回クラッシュはその2日後。

## 設定変更の状況

### リポジトリ管理下(chezmoi)

- `home/dot_config/systemd/user/rclone-gdrive.service`
  `--log-level INFO` → `NOTICE` に変更(2026-08-28)。
  INFOだとVFSキャッシュのクリーナが1分ごとに「掃除対象0件」を出し続け、
  1日約1440行でジャーナルを埋めてクラッシュ解析の妨げになっていた。

### リポジトリ管理外(手動適用・chezmoiには乗らない)

**変更の詳細・元に戻す方法・検証方法は [`system-changes/`](system-changes/README.md) に記録している。**
ここでは本件との関係だけを示す。

| 日時 | 対象 | 内容 | 状態 |
|---|---|---|---|
| 2026-08-25 23:31 | `/etc/default/grub` | `xe.enable_psr=0` を追加 | **撤去済み。効果なし** |
| 2026-08-28 15:56 | `/etc/default/grub` | pstore有効化 + `nowatchdog` 撤去 + `panic=20` | 適用済み・有効 |
| 2026-08-29 17:31 | `/etc/default/grub` | `hardlockup_panic=1` を撤去(無効なパラメータだった) | 適用済み |
| 2026-08-29 17:51 | `/etc/sysctl.d/99-hardlockup.conf` | ハードロックアップ検知の有効化 | 適用済み・有効 |
| 2026-08-29 18:17 | BIOS(リポジトリ外) | 1.3.1 → 1.8.2 | 適用済み |
| 2026-08-28 16:35 | `/etc/systemd/journald.conf.d/99-sync.conf` | `SyncIntervalSec=1s` | 適用済み(有効) |

現在の `GRUB_CMDLINE_LINUX_DEFAULT`:
```
nvme_load=YES splash loglevel=3 hardlockup_panic=1 efi_pstore.pstore_disable=0 panic=20
```

`nowatchdog`(CachyOS既定)を外してハードロックアップ検知を有効化し、
検知時にパニックさせて pstore へ記録を残す構成。**再起動するまで効かない。**
稼働中の状態は `cat /proc/cmdline` で確認すること。

## 未適用の作業

journald の `SyncIntervalSec=1s`(クラッシュ直前のログ取りこぼし対策)は
[`system-changes/2026-08-28-journald-sync.md`](system-changes/2026-08-28-journald-sync.md)
に移した。**これが最優先。**

### 1. Chromeのハードウェア動画デコード無効化(未実施)

全クラッシュが動画再生中に発生している。PSR(表示エンジン)は否定されたが、
動画デコードを担う**メディアエンジン**は別ブロックで未検証。

`/usr/bin/google-chrome-stable` は `~/.config/chrome-flags.conf` を読む。

```
--disable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder
--disable-accelerated-video-decode
```

GPUの描画・合成は残したまま動画デコードだけCPUに逃がす。画質は変わらないが
CPU負荷とバッテリ消費が増える(特に4K/AV1)。恒久設定ではなく数日の実験のつもり。

**実験前に `chrome://gpu` の Video Decode 行を確認すること。**
`Software only` なら最初からHWデコードを使っておらず、この実験は無意味。

### 2. LTSカーネル 6.18.42 での確認(未実施)

`linux-cachyos-lts` は導入済みで、GRUBメニューから選ぶだけ。
8/23の更新前に近い状態に戻せる唯一の手軽な手段。1〜3時間で落ちる状態なので
半日〜1日で判断できる。mesa 26.1.6 は pacman キャッシュに残っていないため、
Mesa側を戻すには Arch Linux Archive が必要。

## 調査で否定した候補

| 候補 | 否定の根拠 |
|---|---|
| PSR / selective fetch | `xe.enable_psr=0` 適用後も3回クラッシュ。警告 `Selective fetch area calculation failed in pipe A` はPSR無効でも毎ブート出るため指標にならない |
| Belkin TB5 Dock | 10時間半正常稼働したブートにも接続中。抜き差しも無事通過。クラッシュ直前30分にドック関連イベントなし |
| WiFi (BE211) | `missed beacons` 大量発生は正常終了ブートで6608件、クラッシュブートで2343件と0件。相関なし。ファームウェアエラー・リセットは全ブート0件 |
| `vivaldi-ffmpeg-codecs` | 導入ファイルは `/opt/vivaldi/libffmpeg.so.8.1` のみでVivaldi専用。Vivaldiは8/23以降未起動。そもそもユーザ空間のコーデックはカーネルをロックできない |
| OOM / メモリ枯渇 | 全ブートで痕跡なし。zram 30GB、swap使用ほぼ0 |
| kernel panic / Oops / MCE / サーマル | 全ブートで記録なし。ACPI BERT も存在しない |
| バッテリ切れ・電源断 | バッテリは満充電容量が設計値と同一、充放電8サイクルで健康 |

## 次にクラッシュしたときの手順

1. **再起動後すぐ** pstore を確認(GRUB診断パラメータ適用後の再起動を経ていること)
   ```bash
   sudo ls -la /sys/fs/pstore/
   sudo cat /sys/fs/pstore/dmesg-efi-*
   ```
   読んだら `sudo rm /sys/fs/pstore/dmesg-efi-*` で消す(EFI変数を圧迫するため)

2. クラッシュしたブートのログ末尾を確認
   ```bash
   journalctl -b -1 -k --no-pager | grep -viE 'UFW BLOCK' | tail -50
   ```

3. `last -x reboot shutdown` でクラッシュ時刻と稼働時間を記録し、上の表に追記

## 補足

- この端末は **SSHで入れない**。`sshd` は disabled/inactive、Tailscaleも `RunSSH: false`。
  フリーズ中の遠隔確認をしたい場合は事前に `sudo tailscale up --ssh` と
  `sudo ufw allow in on tailscale0` が必要。MagicDNSが壊れているのでIP直打ち
  (`ssh keng@100.78.86.32`)。
- ジャーナルは4ブート分程度しか保持されていない。古いクラッシュの記録は失われる。

## 参考

- [omarchy#5573](https://github.com/basecamp/omarchy/issues/5573) — 同型機 XPS 14 DA14260 の
  `xe` ドライバ DSB デッドロック。`Selective fetch area calculation failed` を起点とする
  回帰として報告されている(ただし本件はPSR無効化で再現するため別要因の可能性)
- [omarchy#5953](https://github.com/basecamp/omarchy/issues/5953) — 同型機の周期的ハードリセット。
  ACPI EC / USB-C電力ネゴシエーションを疑う報告(BIOS 1.2.1)

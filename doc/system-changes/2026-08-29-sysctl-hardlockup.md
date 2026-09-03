# 2026-08-29 `/etc/sysctl.d/99-hardlockup.conf` — ハードロックアップ検知の有効化

**状態:** 適用済み(2026-08-29 17:51)。`kernel.nmi_watchdog = 1` / `kernel.hardlockup_panic = 1` を確認済み

## 内容

```ini
kernel.nmi_watchdog = 1
kernel.hardlockup_panic = 1
```

```bash
sudo tee /etc/sysctl.d/99-hardlockup.conf >/dev/null <<'CONF'
# CachyOS は /usr/lib/sysctl.d/70-cachyos-settings.conf で kernel.nmi_watchdog = 0 を
# 設定しており、cmdline から nowatchdog を外しても起動後に無効化されてしまう。
# sysctl.d は数字が大きいほど後勝ちなので 99 で上書きする。
kernel.nmi_watchdog = 1

# hardlockup_panic はブートパラメータとしては認識されない(カーネルが
# "Unknown kernel command line parameters" として userspace に流す)。
# sysctl で設定する必要がある。検知時にパニックさせ pstore に記録を残すため 1。
kernel.hardlockup_panic = 1
CONF
sudo sysctl --system
```

再起動は不要。`sysctl --system` で即時反映される。

## 理由

2026-08-29 17:05 のクラッシュを解析したところ、`journald` の `SyncIntervalSec=1s` は
効いていたにもかかわらず、ハードロックアップのトレースが一切残っていなかった。

原因は、ハードロックアップ検知そのものが無効だったこと。詳細は
[2026-08-28-grub-diagnostics.md](2026-08-28-grub-diagnostics.md) の追記を参照。

なおソフトロックアップ検知(`kernel.watchdog = 1`、閾値10秒)は有効だったが発火しなかった。
つまり「割り込みは生きたままCPUがカーネル内で停止」ではない。割り込みごと止まる
真のハードロックアップか、プラットフォームごと即死したかのどちらかで、
**前者を捕まえられるのは NMI watchdog だけ**。

## 元に戻す方法

```bash
sudo rm /etc/sysctl.d/99-hardlockup.conf
sudo sysctl --system
```

CachyOS が既定で無効にしているのは性能・消費電力のため
(PMUカウンタを1本恒久的に消費する)。問題解決後は戻してよい。

## 検証方法

```bash
sysctl kernel.nmi_watchdog kernel.hardlockup_panic   # 両方 1 になること(root不要)
```

## 注意

`kernel.hardlockup_panic = 1` は誤検知でパニックする可能性がある。
Dell のファームウェアが長い SMI ハンドラを回すと稀に起こりうる。
その場合は `kernel.watchdog_thresh` を既定の10秒から30秒程度へ延ばす。

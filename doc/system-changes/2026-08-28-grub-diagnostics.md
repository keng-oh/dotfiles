# 2026-08-28 15:56 `/etc/default/grub` — ハードロックアップ診断パラメータ

**状態:** 適用済み(2026-08-29 に再起動して反映)。ただし **`hardlockup_panic=1` は無効** — [追記](#2026-08-29-追記-hardlockup_panic1-は効いていなかった)参照

## 内容

```
GRUB_CMDLINE_LINUX_DEFAULT='nvme_load=YES splash loglevel=3 efi_pstore.pstore_disable=0 panic=20'
```

※ 当初は `hardlockup_panic=1` も含めていたが、**無効なパラメータだったため
2026-08-29 17:31 に削除**した(下の追記参照)。

| パラメータ | 意図 |
|---|---|
| `nowatchdog` を削除 | ハードロックアップ検知を有効化(CachyOS既定で無効だった) |
| `hardlockup_panic=1` | 検知時にパニックさせ pstore に記録を残す |
| `efi_pstore.pstore_disable=0` | パニックログをEFI変数へ永続化(カーネル設定が `CONFIG_EFI_VARS_PSTORE_DEFAULT_DISABLE=y` のため明示有効化が必要) |
| `panic=20` | 20秒後に自動再起動 |

同時に `xe.enable_psr=0`([2026-08-25 のエントリ](2026-08-25-grub-xe-psr.md))を撤去した。

## 理由

XPS 14 のハードロックアップがログを一切残さないため、証拠を取る手段を用意する。
`nowatchdog` が入っていたせいで、そもそもハードロックアップが検知されていなかった。

`hardlockup_panic=1` が必要なのは、検知だけではトレースがカーネルログに出るのみで、
マシンが固まっている以上 journald がディスクに書けないため。pstore がダンプするのは
パニック/Oops の瞬間だけなので、記録を残すにはパニックさせる必要がある。

詳細は [`../xps-crash-2026-08.md`](../xps-crash-2026-08.md)。

## 元に戻す方法

`/etc/default/grub.bak2`(2026-08-25 時点)または `/etc/default/grub.bak`(2026-05-14 原本)
から復元し、以下を実行。

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 検証方法

```bash
grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub   # 設定値(root不要)
cat /proc/cmdline                                    # 稼働中カーネルへの反映(root不要)
```

`/proc/cmdline` に反映されていなければ、まだ再起動していないということ。

## 注意

EFI変数に書き込むため、pstore の記録を読んだら消すこと。放置すると蓄積する。

```bash
sudo ls -la /sys/fs/pstore/
sudo cat /sys/fs/pstore/dmesg-efi-*
sudo rm /sys/fs/pstore/dmesg-efi-*
```

現行カーネルは EFI NVRAM の空き容量が50%を切ると書き込みを拒否する保護を持つ。


---

## 2026-08-29 追記: `hardlockup_panic=1` は効いていなかった

2026-08-29 17:05 のクラッシュ後に検証したところ、**ハードロックアップ検知が
2つの理由で完全に無効**だったことが判明した。設置した診断機能は空振りしていた。

### 1. `hardlockup_panic=1` はこのカーネルでは無効なブートパラメータ

カーネル自身がそう言っている:

```
Unknown kernel command line parameters "splash nvme_load=YES hardlockup_panic=1",
will be passed to user space.
```

```
$ sysctl kernel.hardlockup_panic
kernel.hardlockup_panic = 0
```

`/proc/sys/kernel/hardlockup_panic` は存在するので、**sysctl で設定する必要がある**。

### 2. CachyOS が sysctl で NMI watchdog を無効化している

`nowatchdog` を外したことで起動時には有効になる:

```
NMI watchdog: Enabled. Permanently consumes one hw-PMU counter.
```

しかし起動後に `systemd-sysctl` が以下を適用して無効へ戻す:

```
/usr/lib/sysctl.d/70-cachyos-settings.conf:30: kernel.nmi_watchdog = 0
```

```
$ sysctl kernel.nmi_watchdog
kernel.nmi_watchdog = 0
```

**つまり `nowatchdog` をcmdlineから外すだけでは不十分。**
sysctl 側で上書きしないとハードロックアップは永久に検知されない。
対処は [2026-08-29-sysctl-hardlockup.md](2026-08-29-sysctl-hardlockup.md)。

### 効いていたもの

`efi_pstore.pstore_disable=0` は成功している。

```
pstore: Registered efi_pstore as persistent store backend
```

`panic=20` はパニック自体が発生しなかったため出番がなかった。

### cmdline の整理

`hardlockup_panic=1` は **2026-08-29 17:31 に削除済み**(`grub-mkconfig` 実行済み)。
(`nowatchdog` を外した状態は維持すること。これが無いと sysctl で有効化しても
起動時にPMUカウンタが確保されない)

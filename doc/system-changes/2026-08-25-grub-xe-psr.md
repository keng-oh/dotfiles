# 2026-08-25 23:31 `/etc/default/grub` — `xe.enable_psr=0`

**状態:** 撤去済み(2026-08-28 15:56 に[診断パラメータ](2026-08-28-grub-diagnostics.md)へ差し替え)

## 内容

`GRUB_CMDLINE_LINUX_DEFAULT` に `xe.enable_psr=0` を追加。

```
GRUB_CMDLINE_LINUX_DEFAULT='nowatchdog nvme_load=YES splash loglevel=3 xe.enable_psr=0'
```

## 理由

Panther Lake の `xe` ドライバで PSR(パネルセルフリフレッシュ)がハードロックアップの
引き金になっている、という仮説を検証するため。

根拠としたのは、毎ブート出力される警告 `Selective fetch area calculation failed in pipe A` と、
同型機 XPS 14 DA14260 で同じ警告を起点に `xe` の DSB エンジンがデッドロックするという
報告([omarchy#5573](https://github.com/basecamp/omarchy/issues/5573))。

## 結果: 効果なし

適用後も 2026-08-27 に2回、2026-08-28 に1回クラッシュした。

さらに、警告 `Selective fetch area calculation failed in pipe A` は
**PSR を無効化しても毎ブート出力され続けた**。つまりこの警告は PSR の有効/無効と
無関係に出るものであり、**指標として使えない**ことも判明した。

PSR 仮説は否定された。同じ根拠で再び PSR を疑わないこと。

## 元に戻す方法

撤去済みのため作業不要。再度試す場合は `xe.enable_psr` に以下を指定できる
(`modinfo xe` で確認)。

| 値 | 意味 |
|---|---|
| `0` | PSR 完全無効 |
| `1` | PSR1 まで |
| `2` | PSR2 まで |

より限定的な `xe.enable_psr2_sel_fetch=0`(selective fetch のみ無効)もある。

## 検証方法

```bash
cat /proc/cmdline
journalctl -b 0 -k | grep 'Selective fetch'   # PSR無効でも出るため判定に使えない
```

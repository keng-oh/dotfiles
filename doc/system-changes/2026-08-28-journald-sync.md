# 2026-08-28 `/etc/systemd/journald.conf.d/99-sync.conf`

**状態:** 適用済み(2026-08-28 16:35)。journald 再起動済みで**すでに有効**

再起動は不要。journald の設定は `systemctl restart systemd-journald` だけで反映される。

## 内容

```ini
[Journal]
SyncIntervalSec=1s
```

```bash
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/99-sync.conf >/dev/null <<'CONF'
[Journal]
SyncIntervalSec=1s
CONF
sudo systemctl restart systemd-journald
```

## 理由

journald の既定は `SyncIntervalSec=5m` で、ログを最大5分ページキャッシュに溜めてから
fsync する。即時同期されるのは CRIT 以上の優先度のみで、**ERR/WARNING は対象外**。
GPUドライバのエラーやカーネルの警告はこの層に出る。

ハードロックアップ後に電源を強制断すると、ページキャッシュは一度もディスクに
書かれないため、直前最大5分のログが丸ごと消える。

実際 2026-08-28 のクラッシュではディスク上の最終ログが 15:43:03、再起動が 15:45:01 で
**約2分の空白**があった。この空白を当初「カーネルが即死した証拠」と解釈していたが、
単に同期されていなかっただけの可能性がある。過去4回のクラッシュすべてで、
最も見たい部分を取りこぼしていた恐れがある。

詳細は [`../xps-crash-2026-08.md`](../xps-crash-2026-08.md)。

## 元に戻す方法

```bash
sudo rm /etc/systemd/journald.conf.d/99-sync.conf
sudo systemctl restart systemd-journald
```

クラッシュ問題が解決したら `30s`〜`1m` へ緩めるのが落としどころ。
既定の `5m` に戻すと今回と同じく証拠を失う。

## 検証方法

```bash
cat /etc/systemd/journald.conf.d/99-sync.conf   # root不要
```

## 注意

fsync が走るのは新しいログが来たときだけなので、コストはログ量に比例する。
同期頻度を押し上げている主因は UFW のブロックログ(1ブート約838件、中身は
mDNS/IGMP/SSDP の平常トラフィック)。`ufw logging low` などで元を絞る手もある。

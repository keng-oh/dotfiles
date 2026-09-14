#!/bin/bash
# メモリ断片化による画面のカクつき対策。
#
# THP(透過的ヒュージページ)が always だと全プロセスの匿名メモリで2MB連続領域を
# 要求する。長時間稼働でメモリが断片化して2MB連続の在庫(buddyinfo order-9)が
# 尽きると、確保失敗のたびにコンパクションと kswapd が発火し、zram への追い出しと
# 読み戻しが延々と往復する。実測では直接コンパクション停止が20回/秒発生し、
# メモリPSI(full)が4%まで悪化していた。madvise に限定して明示要求時のみ使う。
#
# swappiness は CachyOS 標準の 100 に固定する(実行時に 150 へ書き換わっていた)。
set -euo pipefail
[ -n "${CI:-}" ] && exit 0

# LXC などの非特権コンテナでは /sys や sysctl を書き換えられないためスキップする
if [ -r /proc/1/environ ] && grep -qa 'container=' /proc/1/environ 2>/dev/null; then
  echo "!! コンテナ環境のため vm tuning はスキップしました" >&2
  exit 0
fi

# THP は sysctl では設定できないため tmpfiles 経由で /sys に書き込む
sudo tee /etc/tmpfiles.d/99-transparent-hugepage.conf >/dev/null <<'EOF'
w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise
EOF

sudo tee /etc/sysctl.d/99-vm-tuning.conf >/dev/null <<'EOF'
# zram環境向け。100超は匿名メモリを過剰に追い出しスワップの往復を招くため使わない
vm.swappiness = 100
EOF

echo "==> vm tuning: THP=madvise / swappiness=100 を適用"
sudo systemd-tmpfiles --create /etc/tmpfiles.d/99-transparent-hugepage.conf
sudo sysctl --system >/dev/null

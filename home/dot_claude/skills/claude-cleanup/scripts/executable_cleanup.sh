#!/bin/sh
# ~/.claude の会話履歴・作業記録を掃除する。
#
#   cleanup.sh          対象を一覧表示するだけ(何も消さない)
#   cleanup.sh --yes    一覧の対象を削除する
#
# 消さないもの: settings.json / .credentials.json / skills/ / plugins/ /
#               projects/*/memory/ など、上に列挙した以外のすべて。
# 実行中のセッションを壊さないよう、直近 ACTIVE_MINUTES 分以内に
# 更新されたものは対象から外す。
set -eu

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ACTIVE_MINUTES="${ACTIVE_MINUTES:-60}"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "$CLAUDE_DIR がありません" >&2
  exit 1
fi
cd "$CLAUDE_DIR"

# 対象を列挙する(1行1パス、$CLAUDE_DIR からの相対)
list_targets() {
  # 会話の全文と、セッションIDごとのサブディレクトリ(サブエージェントの記録など)。
  # memory/ は名前で除外する
  if [ -d projects ]; then
    find projects -mindepth 2 -maxdepth 2 ! -name memory ! -mmin "-$ACTIVE_MINUTES"
  fi
  # プロンプトの入力履歴(↑キーで呼び出すもの)
  if [ -f history.jsonl ] && [ -z "$(find history.jsonl -mmin "-$ACTIVE_MINUTES")" ]; then
    echo history.jsonl
  fi
  # 編集前バックアップ・プラン・シェル環境・TODO
  for d in file-history plans shell-snapshots todos; do
    [ -d "$d" ] && find "$d" -mindepth 1 -maxdepth 1 ! -mmin "-$ACTIVE_MINUTES"
  done
  return 0
}

targets="$(list_targets)"

if [ -z "$targets" ]; then
  echo "掃除する対象はありません"
  exit 0
fi

echo "対象 ($CLAUDE_DIR 以下。直近 ${ACTIVE_MINUTES} 分以内に更新されたものは除外):"
echo "$targets" | awk -F/ '{print ($1 == "projects" ? $1 "/" $2 : $1)}' \
  | sort | uniq -c | sed 's/^/  /'
echo "合計: $(echo "$targets" | wc -l | tr -d ' ') 件 / $(echo "$targets" | tr '\n' '\0' | xargs -0 du -sch 2>/dev/null | tail -1 | cut -f1)"

if [ "${1:-}" != "--yes" ]; then
  echo
  echo "(一覧のみ。削除するには --yes を付けて実行)"
  exit 0
fi

echo "$targets" | tr '\n' '\0' | xargs -0 rm -rf --
echo "削除しました"

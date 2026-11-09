#!/bin/sh
# ISSUE の状態を変える唯一の入口。status:* ラベルの付け替えと、
# Project の Status フィールドの更新を一括で行い、両者がずれないようにする。
# 人間の番を表す action:approve / action:merge の付け外しもここだけで行う。
#
#   set-status.sh <ISSUE番号> <状態>
#   状態: triage | needs-refine | needs-approval | ready | in-progress | in-review | approved
#
# Project 側の前提(スコープ・Project・Status 選択肢)が揃っていなければ、
# ラベルにも触れずに終了する(片方だけ変わるのを防ぐ)。
set -eu
. "$(dirname "$0")/lib.sh"

[ $# -eq 2 ] || die "使い方: set-status.sh <ISSUE番号> <状態>"
num=$1
st=$2

line=$(issue_flow_statuses | grep "^$st|" || true)
[ -n "$line" ] && [ "$st" != done ] ||
	die "不明な状態: $st (triage|needs-refine|needs-approval|ready|in-progress|in-review|approved)"
option_name=$(printf '%s' "$line" | cut -d'|' -f2)

need_cmd gh
need_cmd jq
load_repo

# ---- 先に Project 側の前提を全部確認する ----
fix="issue-setup skill で初期化してから再実行する"
has_project_scope || [ $? -eq 2 ] || die "gh に project スコープが無い。$fix"
rc=0
load_project || rc=$?
[ "$rc" -eq 0 ] || die "$(project_error_message "$rc")。$fix"
load_status_field || die "Project #$PROJECT_NUMBER に Status フィールドが無い。$fix"
option_id=$(printf '%s' "$STATUS_OPTIONS" | jq -r --arg n "$option_name" '.[] | select(.name == $n) | .id')
[ -n "$option_id" ] || die "Project の Status に「$option_name」が無い。$fix"

issue=$(gh issue view "$num" --json url,labels,state) || die "ISSUE #$num を取得できない"
url=$(printf '%s' "$issue" | jq -r .url)

# ---- ラベル ----
# status:* を付け替え、人間の番を表す action:approve / action:merge を状態に合わせる。
#   needs-approval → action:approve(action:decide が付いていれば decide を残し、approve は付けない)
#   approved       → action:merge
#   それ以外       → approve / merge / decide を外す
# action:check が付いている間は approve / merge を付けない(check を外した後の
# set-status.sh か setup.sh resync で付く)。同じ状態への呼び出しでも action は揃え直す
old=$(printf '%s' "$issue" | jq -r '[.labels[].name | select(startswith("status:"))] | join(",")')
new="status:$st"
plan=$(printf '%s' "$issue" | jq -r --arg n "$new" --arg st "$st" "$(jq_label_plan)")
add=$(printf '%s' "$plan" | cut -f1)
remove=$(printf '%s' "$plan" | cut -f2)
action=$(printf '%s' "$plan" | cut -f3)
if [ -n "$add" ] || [ -n "$remove" ]; then
	set -- "$num"
	[ -z "$add" ] || set -- "$@" --add-label "$add"
	[ -z "$remove" ] || set -- "$@" --remove-label "$remove"
	gh issue edit "$@" >/dev/null
fi

# ---- Project(item-add は登録済みなら既存の item を返す) ----
item_id=$(gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" --format json --jq .id)
gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" \
	--field-id "$STATUS_FIELD_ID" --single-select-option-id "$option_id" >/dev/null

printf '#%s: %s → %s (Project #%s: %s) 人間の番: %s\n' "$num" "${old:-なし}" "$new" "$PROJECT_NUMBER" "$option_name" "${action:-なし}"

#!/bin/sh
# issue-run が次にやることを一覧する。何も変更しない。
#
#   queue.sh
#
# 出力: 1行1件「種別<TAB>番号<TAB>優先度<TAB>タイトル」。種別の順、同じ種別内は優先度順。
#   起動するもの:
#     review     status:in-review                → issue-review
#     fix        status:in-progress で、PR の最新の判定が不合格 → issue-implement(修正)
#     implement  status:ready で、blocked by が全部閉じている → issue-implement
#     refine     status:needs-refine             → issue-refine
#   起動しないもの(報告用):
#     running    flow:running が付いている(起動中)
#     stale      status:in-progress だが、修正待ちの判定も flow:running も無い(要確認)
#     waiting    status:ready だが、open な blocked by が残っている
#     approval / blocked / approved   人間の番
#     epic-done  open なエピックで、サブ ISSUE が全部閉じている(Roadmap 見直しの時期)
# 1件も無ければ何も出力しない。
set -eu
. "$(dirname "$0")/lib.sh"

need_cmd gh
need_cmd jq

# 優先度ラベルを数値にして並べるための jq 定義
prio='def prio: ([.labels[].name | select(startswith("priority:")) | ltrimstr("priority:")][0] // "none");
def rank: {"critical":0,"high":1,"medium":2,"low":3}[prio] // 4;'

# status ラベル1つ分の open な ISSUE を「番号<TAB>優先度<TAB>running?<TAB>タイトル」で出す
list() {
	gh issue list --state open --label "status:$1" --limit 200 \
		--json number,title,labels |
		jq -r "$prio"' sort_by(rank, .number)[] |
			[.number, prio, (if any(.labels[]; .name == "flow:running") then "1" else "0" end), .title] | @tsv'
}

emit() {
	printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
}

# PR 上の issue-review の判定コメントのうち最新のものが不合格なら 0
last_verdict_failed() {
	_v=$(gh pr list --state open --search "$1 in:body" --json number,body,reviews,comments |
		jq -r --arg n "$1" '
			[.[] | select(.body | test("(?i)(close[sd]?|fix(e[sd])?|resolve[sd]?) #" + $n + "\\b"))
			 | ((.reviews[]? | {t: .submittedAt, b: .body}), (.comments[]? | {t: .createdAt, b: .body}))
			 | select(.b | startswith("## issue-review 判定:"))]
			| sort_by(.t) | last | (.b // "") | (split("\n")[0] // "")')
	case $_v in
	*不合格*) return 0 ;;
	*) return 1 ;;
	esac
}

# blocked by に open なものが残っていれば 0
has_open_blocker() {
	_n=$(gh issue view "$1" --json blockedBy |
		jq '(.blockedBy | if type == "object" then (.nodes // []) else (. // []) end)
			| map(select((.state // "OPEN") == "OPEN")) | length')
	[ "${_n:-0}" -gt 0 ]
}

tab=$(printf '\t')

list in-review | while IFS="$tab" read -r n p r t; do
	if [ "$r" = 1 ]; then emit running "$n" "$p" "$t"; else emit review "$n" "$p" "$t"; fi
done

list in-progress | while IFS="$tab" read -r n p r t; do
	if [ "$r" = 1 ]; then
		emit running "$n" "$p" "$t"
	elif last_verdict_failed "$n"; then
		emit fix "$n" "$p" "$t"
	else
		emit stale "$n" "$p" "$t"
	fi
done

list ready | while IFS="$tab" read -r n p r t; do
	if [ "$r" = 1 ]; then
		emit running "$n" "$p" "$t"
	elif has_open_blocker "$n"; then
		emit waiting "$n" "$p" "$t"
	else
		emit implement "$n" "$p" "$t"
	fi
done

list needs-refine | while IFS="$tab" read -r n p r t; do
	if [ "$r" = 1 ]; then emit running "$n" "$p" "$t"; else emit refine "$n" "$p" "$t"; fi
done

for s in needs-approval:approval blocked:blocked approved:approved; do
	list "${s%%:*}" | while IFS="$tab" read -r n p r t; do
		emit "${s#*:}" "$n" "$p" "$t"
	done
done

gh issue list --state open --label epic --limit 100 --json number,title,labels,subIssuesSummary |
	jq -r "$prio"' .[] | select(.subIssuesSummary.total > 0 and .subIssuesSummary.completed == .subIssuesSummary.total)
		| ["epic-done", .number, prio, .title] | @tsv'

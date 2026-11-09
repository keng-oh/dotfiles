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
#     refine     status:needs-refine、または action:decide で判断待ちのコメントの後に
#                人間の回答がある                 → issue-refine(回答を反映する)
#   起動しないもの(報告用):
#     running    flow:running が付いている(起動中)
#     check      action:check が付いている(要確認。付いている間はどの工程も起動しない)
#     stale      status:in-progress だが、修正待ちの判定も flow:running も無い(要確認)
#     waiting    status:ready だが、open な blocked by が残っている
#     decide     action:decide で、まだ回答が無い  ┐
#     approval   action:approve(方針の承認待ち)    ├ 人間の番
#     approved   action:merge(マージ待ち)          ┘
#     epic-done  open なエピックで、サブ ISSUE が全部閉じている(Roadmap 見直しの時期)
# 人間の回答は、先頭行が DECIDE_MARK(lib.sh)のコメントより後にある、
# 先頭が「## issue-」で始まらないコメント(conventions.md §3「人間の番」)。
# 1件も無ければ何も出力しない。
set -eu
. "$(dirname "$0")/lib.sh"

need_cmd gh
need_cmd jq

# 優先度ラベルを数値にして並べるための jq 定義
prio='def prio: ([.labels[].name | select(startswith("priority:")) | ltrimstr("priority:")][0] // "none");
def rank: {"critical":0,"high":1,"medium":2,"low":3}[prio] // 4;
def has($l): any(.labels[]; .name == $l);'

# status ラベル1つ分の open な ISSUE を「番号<TAB>優先度<TAB>印<TAB>タイトル」で出す。
# 印: running(flow:running)/ check(action:check)/ -(どちらも無い)
list() {
	gh issue list --state open --label "status:$1" --limit 200 \
		--json number,title,labels |
		jq -r "$prio"' sort_by(rank, .number)[] |
            [.number, prio, (if has("flow:running") then "running" elif has("action:check") then "check" else "-" end), .title] | @tsv'
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

# 先に要確認を出す。以降の各状態では check 付きを飛ばす
gh issue list --state open --label action:check --limit 200 --json number,title,labels |
	jq -r "$prio"' sort_by(rank, .number)[] | ["check", .number, prio, .title] | @tsv'

# running / check の印を処理し、どちらでもなければ 1 を返す(呼び出し側が種別を決める)
marked() {
	case $3 in
	running) emit running "$1" "$2" "$4" ;;
	check) ;;
	*) return 1 ;;
	esac
}

list in-review | while IFS="$tab" read -r n p m t; do
	marked "$n" "$p" "$m" "$t" || emit review "$n" "$p" "$t"
done

list in-progress | while IFS="$tab" read -r n p m t; do
	if marked "$n" "$p" "$m" "$t"; then
		:
	elif last_verdict_failed "$n"; then
		emit fix "$n" "$p" "$t"
	else
		emit stale "$n" "$p" "$t"
	fi
done

list ready | while IFS="$tab" read -r n p m t; do
	if marked "$n" "$p" "$m" "$t"; then
		:
	elif has_open_blocker "$n"; then
		emit waiting "$n" "$p" "$t"
	else
		emit implement "$n" "$p" "$t"
	fi
done

list needs-refine | while IFS="$tab" read -r n p m t; do
	marked "$n" "$p" "$m" "$t" || emit refine "$n" "$p" "$t"
done

# needs-approval は action:* で分ける。action:decide は回答の有無で refine / decide
gh issue list --state open --label status:needs-approval --limit 200 --json number,title,labels,comments |
	jq -r --arg mark "$DECIDE_MARK" --arg skill "$SKILL_COMMENT_PREFIX" "$prio"'
        def answered:
            (.comments | sort_by(.createdAt)) as $c
            | ([$c | to_entries[] | select(.value.body | startswith($mark)) | .key] | last) as $i
            | $i != null and any($c[$i + 1:][]; .body | startswith($skill) | not);
        sort_by(rank, .number)[]
        | select(has("action:check") | not)
        | (if has("flow:running") then "running"
           elif has("action:decide") then (if answered then "refine" else "decide" end)
           else "approval" end) as $k
        | [$k, .number, prio, .title] | @tsv'

list approved | while IFS="$tab" read -r n p m t; do
	marked "$n" "$p" "$m" "$t" || emit approved "$n" "$p" "$t"
done

gh issue list --state open --label epic --limit 100 --json number,title,labels,subIssuesSummary |
	jq -r "$prio"' .[] | select(.subIssuesSummary.total > 0 and .subIssuesSummary.completed == .subIssuesSummary.total)
        | ["epic-done", .number, prio, .title] | @tsv'

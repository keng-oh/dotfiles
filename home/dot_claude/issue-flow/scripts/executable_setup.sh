#!/bin/sh
# issue-flow の初期化処理。issue-setup skill からだけ呼ぶ。どれも何度実行しても安全。
#
#   setup.sh labels        不足しているラベルだけ作る(既存ラベルには触れない)
#   setup.sh prune-labels [--yes]
#                          規約に無い status:* ラベルを一覧する。--yes で削除する
#                          (open な ISSUE に付いているものは消さない)
#   setup.sh project       Project を作成/link し、Status の選択肢を規約に揃える
#   setup.sh resync        open な ISSUE の status:* ラベルを Project の Status に反映し直す
#                          (action:approve / action:merge も状態に合わせて揃う)
#   setup.sh actions       action:* の導入前の ISSUE に付ける。needs-approval で action:* が無く
#                          未決事項が残っているものに action:decide と判断待ちのコメントを付け、
#                          続けて resync で approve / merge を揃える
#   setup.sh enable-wiki   リポジトリの Wiki 機能を有効にする
#   setup.sh docs-wiki     GitHub Wiki の代わりに docs/wiki/ を作る(コミットはしない)
set -eu
. "$(dirname "$0")/lib.sh"

need_cmd gh
need_cmd jq
load_repo

labels() {
	have=$(gh label list --limit 500 --json name --jq '.[].name')
	issue_flow_labels | while IFS='|' read -r name color desc; do
		if printf '%s\n' "$have" | grep -qxF "$name"; then
			continue
		fi
		gh label create "$name" --color "$color" --description "$desc" >/dev/null
		printf '作成: %s\n' "$name"
	done
}

prune_labels() {
	yes=0
	[ "${1:-}" != --yes ] || yes=1
	obsolete=$(obsolete_status_labels)
	if [ -z "$obsolete" ]; then
		printf '規約に無い status:* ラベルは無い\n'
		return
	fi
	printf '%s\n' "$obsolete" | while IFS= read -r l; do
		used=$(open_issues_with_label "$l")
		if [ -n "$used" ]; then
			printf '残す: %s(open な %s に付いている。先に set-status.sh で規約の状態に付け替える)\n' "$l" "$used" >&2
		elif [ "$yes" -eq 1 ]; then
			gh label delete "$l" --yes >/dev/null
			printf '削除: %s\n' "$l"
		else
			printf '削除対象: %s\n' "$l"
		fi
	done
	[ "$yes" -eq 1 ] || printf '(--yes を付けて実行すると削除する。close 済みの ISSUE からも外れる)\n'
}

project() {
	has_project_scope || [ $? -eq 2 ] || die "gh に project スコープが無い。ユーザーに gh auth refresh -s project を実行してもらう"

	rc=0
	load_project || rc=$?
	case $rc in
	0) printf '使う Project: #%s「%s」\n' "$PROJECT_NUMBER" "$PROJECT_TITLE" ;;
	1) ;;
	*) die "$(project_error_message "$rc")" ;;
	esac
	if [ "$rc" -eq 1 ]; then
		PROJECT_TITLE=$NAME
		created=$(gh project create --owner "$OWNER" --title "$NAME" --format json)
		PROJECT_NUMBER=$(printf '%s' "$created" | jq -r .number)
		PROJECT_ID=$(printf '%s' "$created" | jq -r .id)
		gh project link "$PROJECT_NUMBER" --owner "$OWNER" --repo "$REPO" >/dev/null
		printf '作成: Project #%s「%s」を %s に link\n' "$PROJECT_NUMBER" "$NAME" "$REPO"
	fi

	load_status_field || die "Project #$PROJECT_NUMBER に Status フィールドが無い(手で作られた Project?)"
	if status_options_ok; then
		printf 'Project #%s の Status 選択肢は規約どおり\n' "$PROJECT_NUMBER"
		return
	fi

	# 選択肢を丸ごと置き換える。同名の既存選択肢は id を渡して値を保つが、
	# 名前の変わる選択肢の値は消えるので、後で resync する
	opts=$(issue_flow_statuses |
		jq -R 'split("|") | {name: .[1], color: .[2], description: ""}' |
		jq -sc --argjson have "$STATUS_OPTIONS" \
			'map(. as $o | ($have | map(select(.name == $o.name)) | .[0].id) as $id | if $id then . + {id: $id} else . end)')
	jq -n --arg f "$STATUS_FIELD_ID" --argjson o "$opts" '{
		query: "mutation($f:ID!,$o:[ProjectV2SingleSelectFieldOptionInput!]){updateProjectV2Field(input:{fieldId:$f,singleSelectOptions:$o}){projectV2Field{... on ProjectV2SingleSelectField{options{name}}}}}",
		variables: {f: $f, o: $o}
	}' | gh api graphql --input - >/dev/null
	printf '更新: Project #%s の Status 選択肢を規約に揃えた(resync を実行すること)\n' "$PROJECT_NUMBER"
}

resync() {
	gh issue list --state open --limit 1000 --json number,labels \
		--jq '.[] | [.number, ([.labels[].name | select(startswith("status:"))][0] // "")] | @tsv' |
		while IFS="$(printf '\t')" read -r n l; do
			[ -n "$l" ] || continue
			if ! issue_flow_statuses | grep -q "^${l#status:}|"; then
				printf '飛ばす: #%s の %s は規約に無い状態(set-status.sh で付け替える)\n' "$n" "$l" >&2
				continue
			fi
			sh "$(dirname "$0")/set-status.sh" "$n" "${l#status:}" </dev/null
		done
}

actions() {
	labels
	gh issue list --state open --label status:needs-approval --limit 200 --json number,body,labels |
		jq -r "$(jq_undecided)"' .[]
            | select(all(.labels[]; .name | startswith("action:") | not))
            | select(undecided) | .number' |
		while IFS= read -r n; do
			gh issue edit "$n" --add-label action:decide >/dev/null
			gh issue comment "$n" --body "$DECIDE_MARK

本文の「未決事項」から選んだ案をコメントしてください。状態やラベルは変えなくてかまいません(issue-run が回答を見つけて反映します)。" >/dev/null
			printf '付与: #%s に action:decide(未決事項あり)\n' "$n"
		done
	resync
}

enable_wiki() {
	gh repo edit "$REPO" --enable-wiki >/dev/null
	printf 'Wiki を有効化した。最初のページは %s/wiki で「Create the first page」から作る必要がある\n' "$REPO_URL"
}

docs_wiki() {
	dir=$(repo_top)/docs/wiki
	mkdir -p "$dir"
	[ -e "$dir/Home.md" ] || printf '# %s Wiki\n\n- [Roadmap](Roadmap.md)\n' "$NAME" >"$dir/Home.md"
	printf '作成: %s(未コミット)\n' "$dir"
}

case ${1:-} in
labels) labels ;;
prune-labels) prune_labels "${2:-}" ;;
project) project ;;
resync) resync ;;
actions) actions ;;
enable-wiki) enable_wiki ;;
docs-wiki) docs_wiki ;;
*) die "使い方: setup.sh labels|prune-labels [--yes]|project|resync|actions|enable-wiki|docs-wiki" ;;
esac

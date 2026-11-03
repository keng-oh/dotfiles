#!/bin/sh
# issue-flow の初期化処理。issue-setup skill からだけ呼ぶ。どれも何度実行しても安全。
#
#   setup.sh labels        不足しているラベルだけ作る(既存ラベルには触れない)
#   setup.sh project       Project を作成/link し、Status の選択肢を規約に揃える
#   setup.sh resync        open な ISSUE の status:* ラベルを Project の Status に反映し直す
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

project() {
	has_project_scope || [ $? -eq 2 ] || die "gh に project スコープが無い。ユーザーに gh auth refresh -s project を実行してもらう"

	if ! load_project; then
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
			sh "$(dirname "$0")/set-status.sh" "$n" "${l#status:}" </dev/null
		done
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
project) project ;;
resync) resync ;;
enable-wiki) enable_wiki ;;
docs-wiki) docs_wiki ;;
*) die "使い方: setup.sh labels|project|resync|enable-wiki|docs-wiki" ;;
esac

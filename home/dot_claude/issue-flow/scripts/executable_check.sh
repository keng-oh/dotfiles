#!/bin/sh
# issue-flow の前提が揃っているかを確認して一覧表示する。何も変更しない。
#
#   check.sh          全項目を確認
#
# 出力: 1行1項目「OK|NG|WARN<TAB>項目<TAB>詳細」
# 終了コード: NG が1つも無ければ 0、あれば 1
set -eu
. "$(dirname "$0")/lib.sh"

ng=0
row() {
	printf '%s\t%s\t%s\n' "$1" "$2" "$3"
	[ "$1" != NG ] || ng=1
}

for c in gh jq git; do
	if command -v "$c" >/dev/null 2>&1; then
		row OK "$c" "$(command -v "$c")"
	else
		row NG "$c" "未インストール"
	fi
done
[ "$ng" -eq 0 ] || exit 1

if gh auth status >/dev/null 2>&1; then
	row OK "gh ログイン" "ログイン済み"
else
	row NG "gh ログイン" "gh auth login が必要"
	exit 1
fi

load_repo
row OK "リポジトリ" "$REPO ($VISIBILITY)"
[ "$VISIBILITY" != PUBLIC ] ||
	row WARN "公開範囲" "PUBLIC: ISSUE・PR・Wiki に識別子(ホスト名・IP・ユーザー名等)を書かない"

# ---- スコープ ----
project_ok=0
if has_project_scope; then
	row OK "gh スコープ" "project あり"
	project_ok=1
else
	case $? in
	1) row NG "gh スコープ" "project が無い。gh auth refresh -s project が必要" ;;
	*)
		row WARN "gh スコープ" "一覧が出ないトークン(fine-grained・環境変数など)。Project の確認で代用する"
		project_ok=1
		;;
	esac
fi

# ---- ラベル ----
have=$(gh label list --limit 500 --json name --jq '.[].name')
missing=$(issue_flow_labels | cut -d'|' -f1 | while IFS= read -r l; do
	printf '%s\n' "$have" | grep -qxF "$l" || printf '%s ' "$l"
done)
if [ -z "$missing" ]; then
	row OK "ラベル" "揃っている"
else
	row NG "ラベル" "不足: $missing"
fi

# ---- Project ----
if [ "$project_ok" -eq 1 ]; then
	rc=0
	load_project || rc=$?
	if [ "$rc" -eq 0 ]; then
		if load_status_field && status_options_ok; then
			row OK "Project" "#$PROJECT_NUMBER「$PROJECT_TITLE」Status 選択肢も規約どおり"
		elif [ -n "${STATUS_FIELD_ID:-}" ]; then
			row NG "Project" "#$PROJECT_NUMBER「$PROJECT_TITLE」の Status 選択肢が規約と違う: $(printf '%s' "$STATUS_OPTIONS" | jq -r '[.[].name] | join(", ")')"
		else
			row NG "Project" "#$PROJECT_NUMBER「$PROJECT_TITLE」に Status フィールドが無い"
		fi
	else
		row NG "Project" "$(project_error_message "$rc")"
	fi
else
	row NG "Project" "スコープ不足で確認できない"
fi

# ---- Wiki ----
top=$(repo_top)
if wiki_reachable; then
	row OK "Wiki" "GitHub Wiki を使う ($REPO_URL/wiki)"
elif [ -d "$top/docs/wiki" ]; then
	row OK "Wiki" "docs/wiki/ を使う(GitHub Wiki は使っていない)"
else
	enabled=$(gh repo view --json hasWikiEnabled --jq .hasWikiEnabled)
	if [ "$enabled" = true ]; then
		row NG "Wiki" "有効だが未初期化。GitHub 上で最初のページを作る必要がある ($REPO_URL/wiki)"
	else
		row NG "Wiki" "無効。有効化するか docs/wiki/ を使う"
	fi
fi

exit "$ng"

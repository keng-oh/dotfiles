# shellcheck shell=sh
# issue-flow のスクリプト群が共有する定義と関数。単体では実行しない(. で読み込む)。
# 対象リポジトリはカレントディレクトリから gh が判定する。

# ---- ラベル定義: 名前|色|説明 ----------------------------------------------
# 種別の bug / enhancement / documentation は GitHub 既定ラベルを流用する。
# 既に存在するラベルは上書きしない(既定ラベルの色・説明を壊さないため)。
issue_flow_labels() {
	cat <<'EOF'
status:triage|ededed|未整理。issue-plan で整理する
status:needs-refine|fbca04|実装前の調査・方針決め待ち (issue-refine)
status:ready|0e8a16|方針確定。実装に着手できる (issue-implement)
status:in-progress|1d76db|実装中
status:in-review|5319e7|PR のレビュー待ち (issue-review)
status:approved|c2e0c6|レビュー通過。人間のマージ待ち
status:blocked|b60205|GitHub の外の要因で停止中 (理由はコメント)
priority:critical|b60205|すぐ対応する
priority:high|d93f0b|次にやる
priority:medium|fbca04|そのうちやる
priority:low|c5def5|余裕があればやる
size:S|bfdadc|小: 1セッションで終わる
size:M|7ebac4|中: 数セッション
size:L|3d7e9a|大: 分割を検討する
bug|d73a4a|Something isn't working
enhancement|a2eeef|New feature or request
documentation|0075ca|Improvements or additions to documentation
chore|fef2c0|保守・雑務 (依存更新、設定変更など)
refactor|d4c5f9|振る舞いを変えない構造の改善
epic|3e4b9e|テーマ単位のまとめ。個別 ISSUE をサブ ISSUE として持つ
EOF
}

# ---- 状態: ラベル接尾辞|Project の Status 選択肢名|色 -----------------------
# 並び順がそのまま Project の Status 選択肢の順になる。
# done はラベルを持たない(close 時に Project の組み込みワークフローが Done にする)。
issue_flow_statuses() {
	cat <<'EOF'
triage|Triage|GRAY
needs-refine|Needs refine|YELLOW
ready|Ready|GREEN
in-progress|In progress|BLUE
in-review|In review|PURPLE
approved|Approved|PINK
blocked|Blocked|RED
done|Done|GREEN
EOF
}

die() {
	printf '%s\n' "$*" >&2
	exit 1
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "$1 が見つからない"
}

# カレントディレクトリのリポジトリ情報を変数に読み込む:
#   REPO (owner/name)  OWNER  NAME  REPO_URL  VISIBILITY
load_repo() {
	_json=$(gh repo view --json nameWithOwner,url,visibility 2>/dev/null) ||
		die "GitHub リポジトリとして認識できない(カレントディレクトリと gh auth status を確認)"
	REPO=$(printf '%s' "$_json" | jq -r .nameWithOwner)
	REPO_URL=$(printf '%s' "$_json" | jq -r .url)
	VISIBILITY=$(printf '%s' "$_json" | jq -r .visibility)
	OWNER=${REPO%%/*}
	NAME=${REPO#*/}
}

# gh トークンのスコープに project があるか。
#   0: ある  1: 無い  2: 判定できない(環境変数のトークン等で一覧が出ない)
has_project_scope() {
	_scopes=$(gh auth status 2>&1 | grep 'Token scopes' || true)
	[ -n "$_scopes" ] || return 2
	printf '%s' "$_scopes" | grep -q "'project'"
}

# リポジトリに link された Project のうち、タイトルがリポジトリ名と一致するものを探す。
# 見つかれば PROJECT_ID と PROJECT_NUMBER を設定して 0 を返す。
load_project() {
	_nodes=$(gh api graphql \
		-f query='query($o:String!,$r:String!){repository(owner:$o,name:$r){projectsV2(first:50){nodes{id number title closed}}}}' \
		-F o="$OWNER" -F r="$NAME" \
		--jq '.data.repository.projectsV2.nodes' 2>/dev/null) || return 1
	_hit=$(printf '%s' "$_nodes" | jq -c --arg t "$NAME" '[.[] | select(.title == $t and (.closed | not))][0] // empty')
	[ -n "$_hit" ] || return 1
	PROJECT_ID=$(printf '%s' "$_hit" | jq -r .id)
	PROJECT_NUMBER=$(printf '%s' "$_hit" | jq -r .number)
}

# Project の Status フィールドを読み込む: STATUS_FIELD_ID と STATUS_OPTIONS (JSON 配列)
load_status_field() {
	_f=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json -L 100 \
		--jq '[.fields[] | select(.name == "Status")][0] // empty' 2>/dev/null) || return 1
	[ -n "$_f" ] || return 1
	STATUS_FIELD_ID=$(printf '%s' "$_f" | jq -r .id)
	STATUS_OPTIONS=$(printf '%s' "$_f" | jq -c '[.options[]? | {id, name}]')
}

# Status の選択肢が規約どおり(名前と順序)なら 0
status_options_ok() {
	_want=$(issue_flow_statuses | cut -d'|' -f2 | jq -R . | jq -sc .)
	_have=$(printf '%s' "$STATUS_OPTIONS" | jq -c '[.[].name]')
	[ "$_want" = "$_have" ]
}

# Wiki のリモートが読めるか(未初期化・無効・権限なしはいずれも失敗になる)
wiki_reachable() {
	GIT_TERMINAL_PROMPT=0 git ls-remote "https://github.com/$REPO.wiki.git" >/dev/null 2>&1
}

repo_top() {
	git rev-parse --show-toplevel 2>/dev/null || die "git リポジトリの中で実行する"
}

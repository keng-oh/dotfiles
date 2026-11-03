#!/bin/sh
# 知見・ロードマップの書き込み先を解決して出力する。初期化はしない。
#
#   wiki-path.sh
#
# 出力(タブ区切り1行): <方式> <ローカルのパス> <ページ URL の接頭辞>
#   wiki  GitHub Wiki を clone/pull した作業コピー。書いたら commit して push する
#   docs  リポジトリ内の docs/wiki/。通常のコミットとして扱う(push はしない)
# どちらも使えなければ非0で終了する(issue-setup で初期化する)。
#
# ページ URL: wiki なら <接頭辞><ページ名>、docs なら <接頭辞><ページ名>.md
set -eu
. "$(dirname "$0")/lib.sh"

need_cmd gh
need_cmd jq
need_cmd git
load_repo

if wiki_reachable; then
	dir=${XDG_CACHE_HOME:-$HOME/.cache}/issue-flow/wiki/$REPO
	if [ -d "$dir/.git" ]; then
		# 前回の書き込みが残っていたら壊さないよう止める
		[ -z "$(git -C "$dir" status --porcelain)" ] ||
			die "Wiki の作業コピーに未コミットの変更がある: $dir"
		git -C "$dir" pull --ff-only -q
	else
		mkdir -p "$(dirname "$dir")"
		git clone -q "https://github.com/$REPO.wiki.git" "$dir"
	fi
	printf 'wiki\t%s\t%s/wiki/\n' "$dir" "$REPO_URL"
	exit 0
fi

top=$(repo_top)
if [ -d "$top/docs/wiki" ]; then
	branch=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
	printf 'docs\t%s\t%s/blob/%s/docs/wiki/\n' "$top/docs/wiki" "$REPO_URL" "$branch"
	exit 0
fi

die "Wiki も docs/wiki/ も使えない。issue-setup skill で初期化する"

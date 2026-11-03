---
name: issue-implement
description: status:ready の GitHub ISSUE を、本文の実装方針どおりに git worktree 上で実装し、テストを通して PR を出す。レビューで変更を求められた PR の修正にも使う。
model: sonnet
disable-model-invocation: true
argument-hint: "<ISSUE番号>"
---

# issue-implement

最初に `~/.claude/issue-flow/conventions.md` を読み、§0 の `check.sh` を実行する。

**ISSUE 本文が仕様書。** 本文の「実装方針」「変更対象ファイル」「テスト方針」に従う。
方針そのものを変える判断はこの skill ではしない(下記「止まるとき」)。

## 1. 着手できるか確かめる

`gh issue view $ARGUMENTS --json number,title,body,labels,blockedBy,comments` を読む。

| 状態 | 扱い |
|---|---|
| `status:ready` | 新規に着手する |
| `status:in-progress` で、PR に変更要求(review のコメント)が付いている | 修正として再開する(手順 2 で既存の worktree に入る) |
| それ以外 | 着手しない。状態を伝え、適切な skill(refine / review)を案内して終わる |

- `blockedBy` に open な ISSUE があれば着手しない。どれ待ちかを伝えて終わる
- 本文の「未決事項」が空でない、または「実装方針」が空なら着手せず、
  `issue-refine` を案内して終わる

## 2. worktree に入る

conventions.md §6 に従う。ブランチは `feature/<N>`(`bug` ラベルなら `fix/<N>`)。

- `.claude/worktrees/<N>` が既にあればそのまま、無ければ作成してから、
  `EnterWorktree` ツールに `path` を渡して入る
- 以降の作業はすべてその worktree の中で行う

新規着手なら `sh ~/.claude/issue-flow/scripts/set-status.sh <N> in-progress`。

## 3. 実装する

- 本文の方針どおりに変更する。CLAUDE.md の約束事に従う
- 方針に書かれていない細部(変数名、小さなヘルパーの切り出し等)は自分で決めてよい
- テスト方針にあるテストを追加・更新する
- 修正として再開した場合は、PR のレビューコメントを読み、指摘に一つずつ対応する
  (`gh pr view <PR> --comments`)

## 4. 検証する

- テスト方針に書かれたコマンドと、CLAUDE.md にあるテスト・lint を実行する
- 失敗したら直す。直せない失敗が残ったまま PR を出さない
- 受け入れ条件を一つずつ見直し、満たしていることを確認する

## 5. PR を出す

1. 意味のある単位でコミットする(リポジトリのコミットメッセージの慣習に合わせる)
2. `git push -u origin <ブランチ>`
3. 新規なら PR を作る:

   ```sh
   gh pr create --title "<ISSUE のタイトル>" --body-file <本文>
   ```

   本文: 先頭に `Closes #<N>`、続けて変更の要約、受け入れ条件ごとの対応内容、
   実行した検証コマンドと結果。修正として再開した場合は、PR にどの指摘にどう対応したかを
   コメントする
4. `set-status.sh <N> in-review`

## 止まるとき

次の場合は**独自の判断で進めない**。理由をまとめて ISSUE にコメントし、
`set-status.sh <N> needs-refine` に戻して終わる(途中のコミットは push しておいてよい):

- 本文の方針どおりでは受け入れ条件を満たせないと分かった
- 本文に書かれていない設計判断(公開 API の形、データ形式、依存の追加など)が必要になった
- 変更対象ファイル以外への大きな変更が必要になった

## 6. 終わりに

- 作業中に見つけたスコープ外の問題はフォローアップ起票する(conventions.md §7)。
  ついでに直さない
- worktree はそのまま残す(レビューの修正で再利用する。片付けはマージ後に人間が行う)
- 変更報告(conventions.md §9)を出し、`/issue-review <N>` を案内する

---
name: issue-review
description: issue-flow で出た PR を、元の GitHub ISSUE の受け入れ条件に照らして検証する。テストを実行し、コードレビューを行い、合格なら status:approved(マージは人間)、不合格なら差し戻す。「#123 をレビューして」「PR を検証して」「in-review のものを見て」などで使う。
model: opus
context: fork
argument-hint: "<ISSUE番号 | PR番号>"
---

# issue-review

最初に `~/.claude/issue-flow/conventions.md` を読み、§0 の `check.sh` を実行する。

実装したセッションとは別のコンテキストで動いている。**実装者の説明を鵜呑みにせず、
ISSUE の受け入れ条件と実際の差分・実行結果だけで判断する。**
マージはしない(人間が行う)。

## 対象の決め方

- `$ARGUMENTS` が ISSUE 番号なら、それを `Closes` している PR を探す:
  `gh pr list --search "<N> in:body" --state open --json number,title,headRefName,body`
- PR 番号なら、本文の `Closes #<N>` から ISSUE を特定する
- 引数が無ければ `status:in-review` の ISSUE を一覧して、優先度の高いものから1件
- ISSUE が `status:in-review` でなければ、状態を報告して終わる

## 手順

1. **読む**
   - ISSUE: `gh issue view <N> --json title,body,labels,comments`(受け入れ条件・方針・スコープ外)
   - PR: `gh pr view <PR> --json title,body,files,commits,comments,reviews`
   - 差分: `gh pr diff <PR>`

2. **動かして確かめる**。PR のブランチを取得し、手元の作業ツリーを汚さない場所で検証する:

   ```sh
   git fetch origin <headRefName>
   git worktree add --detach "$TMPDIR/review-<PR>" origin/<headRefName>
   ```

   (`TMPDIR` が無ければスクラッチ用のディレクトリを使う)そこで、本文のテスト方針と
   CLAUDE.md にあるテスト・lint を実行する。終わったら `git worktree remove` で片付ける。

3. **コードを見る**
   - `code-review` skill が使えれば、PR を対象に実行して結果を取り込む
   - それに加えて、次を自分で確認する:
     - 受け入れ条件の一つ一つが、差分とテストで本当に満たされているか
     - 本文の実装方針から外れていないか。外れているなら、その理由が PR に書かれているか
     - スコープ外の変更が紛れ込んでいないか
     - テストが条件を実際に検証しているか(通るだけのテストになっていないか)
     - PUBLIC リポジトリなら、識別子や秘密が差分に含まれていないか

4. **判定を PR にコメントする**。本文の1行目は必ず `## issue-review 判定: 合格` か
   `## issue-review 判定: 不合格`(差し戻しの回数をこの見出しで数える。conventions.md §3)。
   続けて受け入れ条件ごとに ✅/❌ と根拠、実行したコマンドと結果、
   その他の指摘(必須 / 任意を区別)を書く:

   ```sh
   gh pr review <PR> --approve --body-file <本文>          # 合格
   gh pr review <PR> --request-changes --body-file <本文>  # 不合格
   ```

   自分の PR には approve / request-changes ができない(GitHub の仕様)。
   失敗したら `gh pr comment <PR> --body-file <本文>` で同じ内容をコメントする。

5. **状態を変える**
   - 合格 → `set-status.sh <N> approved`。マージは人間に委ねる旨を報告する
   - 実装の不備で不合格 → PR のレビューとコメントのうち、見出しが
     `## issue-review 判定: 不合格` のものの数を数える(今回の分を含む):
     - 2回以下 → `set-status.sh <N> in-progress`。`/issue-implement <N>` で修正するよう案内
     - 3回目 → 差し戻さない。ISSUE に「3回不合格。残っている指摘と、方針か条件の見直しが
       要りそうか」をコメントして `set-status.sh <N> blocked`(人間が判断する)
   - 方針自体に問題がある(方針どおりでは条件を満たせない、条件そのものが不適切)→
     ISSUE に理由をコメントして `set-status.sh <N> needs-refine`

6. **後始末**
   - 必須ではない改善点やスコープ外の問題は、PR に書くだけでなくフォローアップ起票する
     (conventions.md §7)
   - レビューで分かった、この PR を超えて役立つ知見があれば Wiki に追記する(conventions.md §5)

7. 変更報告(conventions.md §9)を出す。

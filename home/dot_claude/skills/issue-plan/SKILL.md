---
name: issue-plan
description: GitHub ISSUE を起票・整理する。エピックを実装可能な個別 ISSUE に分解してサブ ISSUE として登録したり、バグ報告や思いつきを ISSUE にしたり、既存 ISSUE の優先度やラベルを見直したりする。「ISSUE を作って」「タスクに分解して」「エピックを分解」「これを ISSUE にしておいて」「優先順位を見直して」「ラベルを整理して」などで使う。方針そのものを決める話は issue-roadmap、個々の ISSUE の調査・実装方針は issue-refine が担当する。
argument-hint: "[エピック番号 | 起票したい内容]"
---

# issue-plan

最初に `~/.claude/issue-flow/conventions.md` を読み、§0 の `check.sh` を実行する。

この skill が書くのは本文テンプレート(conventions.md §4)の
**「背景・目的」と「受け入れ条件」まで**。実装方針は書かない(issue-refine の担当)。

## 何をするかの判断

| 依頼 | やること |
|---|---|
| エピック番号が渡された / 「分解して」 | A. エピックの分解 |
| 具体的な要望・バグ報告 | B. 単発の起票 |
| 「優先度を見直して」「整理して」 | C. 棚卸し |
| Roadmap に無い大きなテーマの話 | 起票せず `issue-roadmap` を案内する |

## 共通の下準備

- Wiki の `Roadmap` を読む(`sh ~/.claude/issue-flow/scripts/wiki-path.sh` でパスを得る)。
  「やらないこと」に当たる要望は起票せず、その旨をユーザーに伝える
- 重複確認: `gh issue list --state all --search "<キーワード>" --json number,title,state`
  で似た ISSUE を探す。あれば新規に作らず、既存のものへの追記を検討する

## A. エピックの分解

1. `gh issue view <エピック> --json title,body,subIssues` で目的・完了の定義・既存のサブ ISSUE を読む
2. 完了の定義を満たすのに必要な作業を洗い出し、**1 ISSUE = 1 PR でレビューできる大きさ**に切る。
   既存のサブ ISSUE と重ならないようにする
3. 分解案(タイトル・一行説明・優先度・順序)を表にしてユーザーに見せてから起票する。
   ここは件数がまとまるため、作る前に一度見せる
4. 各 ISSUE を起票する:

   ```sh
   gh issue create --title "..." --body-file <本文> \
     --label <種別>,priority:<...> --parent <エピック番号>
   ```

   本文はテンプレートの全見出しを含め、「背景・目的」「受け入れ条件」を埋める。
   受け入れ条件は**検証できる形**で書く(「いい感じにする」ではなく、何が起きれば合格か)
5. 状態を付ける: `sh ~/.claude/issue-flow/scripts/set-status.sh <N> needs-refine`
   - 調査不要なほど明確で小さいもの(タイポ修正、設定値の変更など)は、
     「実装方針」「変更対象ファイル」も埋めたうえで `ready` にしてよい
6. 分解中に気づいた順序の制約は、ISSUE 間なら blocked by で登録してよい
   (`gh issue edit <N> --add-blocked-by <M>`)。確信が無ければ refine に任せる

## B. 単発の起票

1. 要望から「背景・目的」「受け入れ条件」を書く。足りない情報はユーザーに聞く
   (バグなら再現手順・期待する動作・実際の動作)
2. 属するエピックがあれば `--parent` を付ける
3. 起票し、`set-status.sh <N> needs-refine`(または上記の条件で `ready`)

## C. 棚卸し

1. open な ISSUE を一覧する:
   `gh issue list --state open --limit 300 --json number,title,labels,parent,createdAt`
2. 次を探して、修正案を表にまとめる:
   - 状態・優先度・種別のいずれかのラベルが無い / 状態ラベルが2つ以上ある
   - `status:triage` のまま放置されているもの
   - Roadmap の順序と優先度が食い違うもの
   - エピックに属すべきなのに親が無いもの
   - 長期間動きが無く、もう不要そうなもの
3. ラベルの付け直しは自律で行ってよい(状態は `set-status.sh` で)。
   **close する案だけは**ユーザーに確認してから実行する

## 最後に

変更報告(conventions.md §9)を出し、次の一手を案内する
(通常は優先度の高い `needs-refine` の ISSUE に対する `issue-refine`)。

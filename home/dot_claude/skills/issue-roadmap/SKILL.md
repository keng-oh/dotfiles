---
name: issue-roadmap
description: ISSUE を作る前の段階で、プロジェクトの目的・テーマと優先順・やらないこと・技術方針をユーザーと対話して決め、Wiki の Roadmap ページとテーマごとのエピック ISSUE に記録する。「ロードマップを考えたい」「今後の方針を決めたい」「何から作るか整理したい」「方向性を見直したい」「エピックを作って」など、個別タスクより上のレベルの計画を求められたら使う。個別 ISSUE への分解は issue-plan が行う。
model: opus
argument-hint: "[検討したいテーマや見直したい点]"
---

# issue-roadmap

最初に `~/.claude/issue-flow/conventions.md` を読み、§0 の `check.sh` を実行する。

**方針を決めるのはユーザー。** モデルは材料を集め、選択肢と判断材料を示し、
決まったことを記録する。自分の好みで方針を書き込まない。

## 手順

1. **現状を把握する**
   - `sh ~/.claude/issue-flow/scripts/wiki-path.sh` で書き込み先を得て、`Roadmap` と `Home` を読む
   - エピック: `gh issue list --label epic --state all --json number,title,state,subIssuesSummary`
   - open な ISSUE の全体: `gh issue list --state open --limit 200 --json number,title,labels`
   - CLAUDE.md、README、主要なコードの構成をざっと見る
   - 引数があれば、それを今回の検討の焦点にする

2. **対話して決める**。一度に全部聞かず、論点ごとに `AskUserQuestion` で選択肢を出す
   (推奨があれば理由とともに先頭に置く)。決める論点:
   - ビジョン: このプロジェクトは誰の何を解決するか(既にあれば変更の有無だけ確認)
   - 現在のフェーズ: 何を達成したら次に進むか
   - テーマ(=エピック候補)と順序: 3〜7個程度。依存関係があれば順序に反映
   - やらないこと: 明示的に除外する範囲(後で議論が蒸し返されないように)
   - 技術方針・制約: 使う/使わない技術、守るべき制約
   既存の Roadmap を見直す場合は、変更点だけを論点にする

3. **Roadmap を書く**(Wiki の `Roadmap` ページ)。構成:

   ```markdown
   # Roadmap
   ## ビジョン
   ## 現在のフェーズ
   ## テーマ(順序つき)
   1. [テーマ名](エピック ISSUE のフル URL) — 一行説明
   ## やらないこと
   ## 技術方針・制約
   ## 改訂履歴
   - YYYY-MM-DD: 何を変えたか(きっかけ)
   ```

   エピックの URL は手順 4 の後で埋める。`Home` にも `Roadmap` へのリンクが無ければ足す。

4. **エピックを作成・更新する**。テーマ1つにつき1件、`epic` ラベルと優先度ラベル。
   `status:*` は付けない。本文:

   ```markdown
   ロードマップ: <Roadmap ページの URL>

   ## 目的
   ## 完了の定義
   <!-- これが満たされたらエピックを閉じる、という検証可能な条件 -->
   ## 設計の大枠
   ## 未決事項
   ```

   既存のエピックで不要になったものは、理由をコメントして `--reason "not planned"` で閉じる
   (サブ ISSUE が残っていればユーザーに扱いを確認する)。

5. Wiki を commit・push する(`docs` 方式なら commit のみ)。

6. 変更報告(conventions.md §9)を出し、次は `issue-plan` でエピックを
   個別 ISSUE に分解するよう案内する。

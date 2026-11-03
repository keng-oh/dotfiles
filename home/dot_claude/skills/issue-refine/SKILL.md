---
name: issue-refine
description: GitHub ISSUE を実装前に検討する。コードや外部仕様を調査し、対応可否を判断し、実装方針・変更対象ファイル・テスト方針を決めて ISSUE 本文を肉付けし、依存関係とサイズを登録して status:ready にする。再利用できる知見は Wiki に残す。「#123 を検討して」「この ISSUE を調査して」「実装方針を決めて」「着手できる状態にして」「needs-refine を片付けて」などで使う。
model: opus
argument-hint: "<ISSUE番号>"
---

# issue-refine

最初に `~/.claude/issue-flow/conventions.md` を読み、§0 の `check.sh` を実行する。

目標は、**別セッションの Sonnet が本文だけを読んで迷わず実装できる状態**にすること。
曖昧さを implement に持ち越さない。

## 対象の決め方

- 番号が渡されたらそれ
- 無ければ `gh issue list --label status:needs-refine --json number,title,labels` から
  優先度の高い順に候補を示し、ユーザーに選んでもらう

対象が `status:needs-refine` / `status:triage` / `status:blocked` 以外なら、
状態を伝えて続けるか確認する(ready 済みの見直しなどはありうる)。

## 手順

1. **読む**
   - `gh issue view <N> --json title,body,labels,parent,blockedBy,comments`
   - 親エピックがあればその本文(目的・設計の大枠)
   - Wiki の `Home` から関連しそうなページ(`wiki-path.sh` でパスを得る)
   - CLAUDE.md(テスト・lint の実行方法、リポジトリの約束事)

2. **調査する**
   - 関係するコードを読み、変更が及ぶ範囲を特定する。似た既存実装や流用できる関数を探す
   - 外部ライブラリ・API・仕様が絡むなら、ドキュメントで実際の挙動を確かめる
   - 必要なら小さく試す(スクラッチで実行する等)。ただしリポジトリは変更しない

3. **対応可否を判断する**
   - 実装すべきでない(目的が既に満たされている、Roadmap の「やらないこと」に当たる、
     費用に見合わない等)→ 理由をコメントして `gh issue close <N> --reason "not planned"`。
     判断が微妙ならユーザーに確認する
   - 方針を決めるのにユーザーの判断が要る(仕様の選択、トレードオフ)→
     選択肢と推奨を示して `AskUserQuestion` で聞く。この場で答えが得られなければ
     未決事項に書いて `set-status.sh <N> blocked` とし、理由をコメントする
   - 大きすぎる(`size:L`)→ 分割案を示す。了承されたら分割後の ISSUE を
     issue-plan の手順で起票し、元の ISSUE は分割先へのリンクをコメントして閉じるか、
     エピックに格上げする

4. **本文を更新する**(`gh issue edit <N> --body-file <新しい本文>`)。
   テンプレートの「調査結果」「実装方針」「変更対象ファイル」「テスト方針」
   「スコープ外」「未決事項」を埋める。受け入れ条件に抜けや検証できない項目があれば直す。
   - 実装方針: 何をどう変えるか。選ばなかった案とその理由を一言
   - 変更対象ファイル: パスと、そこで何をするか
   - テスト方針: 追加・更新するテストと、実行するコマンド
   - 調査結果: 要点だけ。詳細は Wiki に書いてリンクする

5. **依存とサイズ**
   - 他の ISSUE の完了が前提なら `gh issue edit <N> --add-blocked-by <M>`
   - `size:S|M|L` を付ける(`gh issue edit <N> --add-label size:M`。既存の size は外す)

6. **知見を Wiki に残す**(conventions.md §5)。この ISSUE を超えて役立つことだけ:
   コード構造の理解、ハマりどころ、外部仕様の調べた結果など。
   話題に合うトピックページに追記し、出典としてこの ISSUE のフル URL を付ける。
   新しいページを作ったら `Home` にも載せる。最後に commit・push(docs 方式は commit のみ)

7. **状態を決める**
   - 未決事項が空で、未解決の blocked by が無い → `set-status.sh <N> ready`
   - blocked by が残っている → `ready` にしてよい(implement が着手時に確認する)。
     ただし報告で「#M 待ち」と伝える
   - 未決事項が残っている → `ready` にしない

8. 調査中に見つけたスコープ外の問題はフォローアップ起票する(conventions.md §7)。

9. 変更報告(conventions.md §9)を出す。ready にした場合は
   `/issue-implement <N>` を新しいセッションで実行するよう案内する。

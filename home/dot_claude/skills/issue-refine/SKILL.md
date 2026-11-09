---
name: issue-refine
description: GitHub ISSUE を実装前に検討する。コードや外部仕様を調査し、対応可否を判断し、実装方針・変更対象ファイル・テスト方針を決めて ISSUE 本文を肉付けし、依存関係とサイズを登録して status:needs-approval(人間の承認待ち)にする。再利用できる知見は Wiki に残す。「#123 を検討して」「この ISSUE を調査して」「実装方針を決めて」「着手できる状態にして」「needs-refine を片付けて」などで使う。
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

対象が `status:needs-refine` / `status:triage` / `status:needs-approval`
以外なら、状態を伝えて続けるか確認する(ready 済みの見直しなどはありうる)。
`in-progress` 以降のものは、実装・レビューが進行中なので本文を書き換えない
(conventions.md §3「計画の見直しと進行中の ISSUE」)。

差し戻しで `needs-refine` に戻ってきた ISSUE は、コメント(人間の指摘、implement や
review が戻した理由)を必ず読み、それへの対応を本文に反映する。

`needs-approval` で `action:decide` が付いている ISSUE は**判断待ち**。
`## issue-refine 判断待ち` のコメントより後に人間の回答(`## issue-` で始まらないコメント)が
あれば、下の「回答の反映」だけを行う。回答が無ければ、何も変えずに「回答待ち」と報告して終わる
(conventions.md §3「判断待ちの回し方」)。

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
   - **判断が要る点**(conventions.md §10。使う人から見える挙動が選び方で変わるもの)がある →
     推奨案があっても自分で決めない。§10 の形(選択肢ごとに、起きる状況・何が起きるか・
     困る場面。推奨を先頭に)で示す:
     - 対話で実行しているとき → `AskUserQuestion` で聞く(推奨を先頭に)。
       答えを本文に反映する
     - 自動実行などで聞けないとき → §10 の形で「未決事項」に書き、手順 8 で
       `action:decide` を付けて `needs-approval` にする。推奨案で決めて本文のほかの節
       (「挙動の決定」など)に書いて済ませない
     - どちらの場合も、判断が要る点以外がすべて決まっているなら、本文のほかの節は埋めておく
       (答えが出たら、その点を反映するだけで `needs-approval` にできるように)
   - 内部の作りだけの違い(使う人から見えない差)は自分で決めてよい。
     そう判断したことを変更報告に一言書く(conventions.md §10)
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

7. 調査中に見つけたスコープ外の問題はフォローアップ起票する(conventions.md §7)。
   元の ISSUE へのコメントは、先頭行を `## issue-refine フォローアップ` にする
   (`## issue-` で始まらないと、判断待ちへの人間の回答と誤認される)

8. **状態を決める**。**`ready` には自分でしない**(承認は人間が行う。conventions.md §3)。
   `action:approve` は `set-status.sh` が付けるので、手で付けない
   - 未決事項が空 → `set-status.sh <N> needs-approval`(`action:approve` が付く)。
     ISSUE に、先頭行 `## issue-refine 承認待ち` で「承認なら `ready` に、
     直す点があればコメントして `needs-refine` に」と短くコメントする
   - 未決事項が残っている → 先に `gh issue edit <N> --add-label action:decide`、
     続けて `set-status.sh <N> needs-approval`(decide があるので approve は付かず、付いていれば外れる)。
     ISSUE には、先頭行を `## issue-refine 判断待ち` にして、未決事項と同じ選択肢(§10 の形)と
     「選んだ案をコメントしてください。状態やラベルは変えなくてかまいません」を書く
   - blocked by が残っていても `needs-approval` にしてよい(implement が着手時に確認する)。
     ただし報告で「#M 待ち」と伝える

9. 変更報告(conventions.md §9)を出す。`action:approve` になった場合は本文を確認して
   承認するよう案内する(承認後は `/issue-implement <N>` で実装に進む)。
   `action:decide` になった場合は、選択肢をその場にも並べ、コメントで答えるよう案内する。

## 回答の反映(判断待ちに人間が答えたとき)

1. 本文と、判断待ちのコメント以降のコメントを読む。回答がどの未決事項のどの案を選んだかを特定する
2. 選ばれた案を本文の該当する節(実装方針・受け入れ条件・テスト方針など)に反映し、
   その未決事項を「未決事項」から消す。回答に新しい指摘があれば、それも本文に反映する
3. 状態を決める:
   - 未決事項が空になった → `gh issue edit <N> --remove-label action:decide` のあと
     `set-status.sh <N> needs-approval`(`action:approve` に替わる。状態は `needs-approval` のまま)。
     先頭行 `## issue-refine 承認待ち` で、何を反映したかと「承認なら `ready` に」をコメントする
   - 回答が一部だけ・読み取れない・新しい判断が要る点が出た → `action:decide` のまま、
     残った点を手順 8 と同じ形の `## issue-refine 判断待ち` コメントで示し直す
4. 変更報告を出す

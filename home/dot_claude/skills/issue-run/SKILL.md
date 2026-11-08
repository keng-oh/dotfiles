---
name: issue-run
description: issue-flow の自動で回せる工程(refine / implement / review)を、カレントディレクトリのリポジトリについて状態ラベルから振り分け、ISSUE ごとにエージェントを並列で起動する。`/loop /issue-run` で定期実行する前提。「issue-flow を回して」「自動で進めて」「ループで開発して」などで使う。人間の承認・判断・マージが要るものには手を出さず、一覧で報告する。
model: sonnet
disable-model-invocation: true
argument-hint: "[--max <並列数>]"
---

# issue-run

最初に `~/.claude/issue-flow/conventions.md` を読み、§0 の `check.sh` を実行する
(NG なら起動せず、内容を報告して終わる)。

**この skill は振り分け役。** 自分で調査・実装・レビューをしない。
各工程は担当 skill の手順に従うエージェントに任せる。
対象はカレントディレクトリのリポジトリだけ。

## 1. やることを一覧する

```sh
sh ~/.claude/issue-flow/scripts/queue.sh
```

出力の各行は「種別 / 番号 / 優先度 / タイトル」。種別の意味はスクリプト冒頭のコメントのとおり。
**何も出力されなければ「対象なし」と1行で報告して終わる**(定期実行なので、空の回を短く済ませる)。

## 2. 起動するものを決める

- 並列数の上限は `--max` の値、無ければ **3**。このセッションで起動して、まだ終わっていない
  エージェントの数を差し引いた分だけ起動する
- 起動する種別の優先順: `review` → `fix` → `implement` → `refine`
  (完了に近いものから片付ける)。同じ種別内は queue.sh の並び(優先度順)
- `running` は、このセッションで起動したもの以外は**前のセッションの残り**。
  触らずに「要確認(flow:running が残っている)」として報告する

## 3. 起動する

ISSUE ごとに、先にラベルで印を付けてからエージェントを起動する(二重起動の防止):

```sh
gh issue edit <N> --add-label flow:running
```

`Agent` ツールで起動する。種別ごとの担当:

| 種別 | 読ませる skill | model |
|---|---|---|
| `review` | `~/.claude/skills/issue-review/SKILL.md` | opus |
| `fix` / `implement` | `~/.claude/skills/issue-implement/SKILL.md` | sonnet |
| `refine` | `~/.claude/skills/issue-refine/SKILL.md` | opus |

プロンプトには次をすべて含める(エージェントはこの会話の文脈を持たない):

```text
<リポジトリの絶対パス> のリポジトリで、ISSUE #<N> を処理する。
~/.claude/skills/<skill>/SKILL.md を読み、その手順に従う。手順中の $ARGUMENTS は <N>。

自動実行中なので、次を守る:
- ユーザーは不在。AskUserQuestion は使わない。ユーザーの判断が要る点は、skill の
  手順どおり ISSUE にコメントして止まる(refine なら未決事項に書いて blocked)
- 判断が要る点は ~/.claude/issue-flow/conventions.md §10 に従う(推奨案があっても自分で
  決めず、§10 の形で選択肢を示す)。最終報告にも同じ選択肢を載せる
- 状態の変更は skill の手順どおり set-status.sh で行う。ready と approved 以降へは
  skill が定める遷移しかしない(conventions.md §3「人間が持つ遷移」)
- EnterWorktree は使わない。worktree を作ったら、以降の Bash はその絶対パスに cd してから
  実行し、ファイルは絶対パスで編集する(他の ISSUE のエージェントと並列で動いている)
- PUBLIC リポジトリで、識別子(ホスト名・IP・ユーザー名など)を書かないと進めない場合は、
  GitHub に何も書かずに止まり、その旨を最終報告に書く
- flow:running ラベルには触れない(起動側が外す)
- 最終報告には、変更報告(conventions.md §9)の表と、止まった場合はその理由を含める
```

## 4. 終わったエージェントの後始末

エージェントの完了通知を受けたら(失敗・中断でも):

1. `gh issue edit <N> --remove-label flow:running`
2. 報告を読み、ISSUE の状態が想定どおり進んだか確かめる
   (`gh issue view <N> --json labels`)。状態が変わっていなければ「進まなかった」として報告する

## 5. 報告

各回の最後に、短くまとめる。前回の報告から変化が無ければ「変化なし」の1行でよい。

- 今回起動したもの・完了したもの(完了したものはエージェントの変更報告の表を連結する)
- **人間の番**: `approval`(承認待ち)/ `blocked`(判断待ち。理由のコメントへのリンク)/
  `approved`(マージ待ち)
  - `blocked` のうち判断が要る点で止まっているものは、リンクだけでなく、
    判断が要る点を選択肢つき(conventions.md §10 の形)でその場に並べる。
    報告を読むだけで選べるようにする。選択肢はエージェントの最終報告から、
    無ければ ISSUE 本文の「未決事項」(`gh issue view <N> --json body`)から取る
- 要確認: `stale`、前のセッションの `running`、進まなかったもの
- `waiting`: どの ISSUE 待ちか
- `epic-done`: サブ ISSUE が全部閉じたエピック。`/issue-roadmap` での見直しを勧める
  (エピックは自動で閉じない)

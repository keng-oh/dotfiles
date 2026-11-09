---
name: issue-setup
description: GitHub ISSUE ドリブン開発(issue-flow)の前提を確認し、足りないものだけ初期化する。gh のログインとスコープ、ラベル、GitHub Projects、Wiki(または docs/wiki/)、テストの実行方法を点検する。「ISSUE 駆動で始めたい」「issue-flow の準備」「ラベルや Project を用意して」「Wiki が無いと言われた」、または他の issue-* skill が前提不足で止まったときに使う。何度実行しても安全で、2回目以降は状態確認として使える。
---

# issue-setup

最初に `~/.claude/issue-flow/conventions.md` を読む。
初期化処理は**この skill にしか書かない**。他の skill は不足を見つけるとここへ案内してくる。

スクリプト: `S=~/.claude/issue-flow/scripts`(対象リポジトリの中で実行する)

## 手順

1. 現状を確認して、結果の表をそのままユーザーに見せる:

   ```sh
   sh $S/check.sh
   ```

   NG も「不要なラベル」「action ラベル」の WARN も無ければ手順 3 へ。

2. NG の項目と「不要なラベル」「action ラベル」の WARN だけ、上から順に対処する。各手順の後に `check.sh` をもう一度実行して確かめる。

   | 項目 | 対処 |
   |---|---|
   | gh / jq / git | パッケージの導入をユーザーに依頼する(OS ごとのパッケージリストに従う) |
   | gh ログイン | `gh auth login` をユーザーに実行してもらう(対話的なので代行できない) |
   | gh スコープ | `gh auth refresh -s project` をユーザーに実行してもらう。ブラウザでの承認が要る |
   | ラベル | `sh $S/setup.sh labels`。既存ラベルには触れず、足りないものだけ作る |
   | 不要なラベル(NG) | 規約に無い状態ラベルが open な ISSUE に付いている。ISSUE ごとに今の規約のどの状態にするかをユーザーに確認し、`set-status.sh <N> <状態>` で付け替える。終わったら下の WARN の対処へ |
   | 不要なラベル(WARN) | `sh $S/setup.sh prune-labels` で削除対象を見せ、ユーザーの了承を得てから `sh $S/setup.sh prune-labels --yes`。close 済みの ISSUE からも外れることを伝える |
   | Project | `sh $S/setup.sh project`。「選択肢を規約に揃えた」と出たら続けて `sh $S/setup.sh resync` |
   | action ラベル(WARN) | 人間の番(conventions.md §3)の `action:*` を導入する前に `needs-approval` / `approved` になった ISSUE。`sh $S/setup.sh actions` で、未決事項が残っている `needs-approval` に `action:decide` と判断待ちのコメントを付け、ほかは resync で `action:approve` / `action:merge` を付ける。コメントを書き込むので、対象の番号を見せてから実行する。Project の項目より後に行う(resync が Project を使うため) |
   | Wiki | 下記「Wiki の準備」 |

   ユーザーに実行してもらうコマンドは、`! <コマンド>` の形でこのセッションから
   実行できることも伝える。**`gh auth` 系は Claude が実行してはいけない**
   (settings.json の deny で禁止している)。スコープの追加はユーザーの判断で行うもの。
   必要なスコープは `project` だけで、それ以上を求めない。

3. **テスト・lint の実行方法**を特定する。CLAUDE.md、Makefile、package.json、
   pyproject.toml、Cargo.toml、CI の設定(`.github/workflows/`)などから探す。
   - 見つかったら報告する。CLAUDE.md に書かれていなければ、追記案を**提案だけ**する
     (issue-implement / issue-review はそれを読んで検証する)
   - 見つからなければユーザーに聞く。テストが無いリポジトリならその旨を記録案に含める

4. 最後に `check.sh` が全項目 OK になったことを示し、変更報告(conventions.md §9)を出す。
   次の一手として `issue-roadmap`(方針がまだ無い場合)か `issue-plan` を案内する。

## Wiki の準備

GitHub Wiki を優先し、使えなければ `docs/wiki/` にする。

1. `check.sh` が「無効」と出した → `sh $S/setup.sh enable-wiki` を試す
   - 失敗した(Free プランの private リポジトリなど)→ 手順 3 へ
2. 「有効だが未初期化」→ 最初のページは API では作れない。ユーザーに
   `<リポジトリURL>/wiki` を開いて **「Create the first page」でそのまま保存**してもらう
   (中身は後で Claude が書き換えるので空でよい)。済んだら `check.sh` で確認する
   - ユーザーが見送った場合は手順 3 へ
3. `sh $S/setup.sh docs-wiki` で `docs/wiki/` を作り、ユーザーに伝えてからコミットする
   (push はしない)

PUBLIC リポジトリでは Wiki も全世界に公開されることを、有効化の前に一言伝える。

## 注意

- Project の Status 選択肢を置き換えると、既存の item の Status 値は消える。
  そのため `project` の後は必ず `resync` でラベルから復元する
- Project の組み込みワークフロー(close で Done にする等)は API で設定できない。
  新規作成した Project は既定で有効になっているが、念のため Project の
  Workflows 画面で「Item closed」「Pull request merged」が Done になっているか
  確認するようユーザーに伝える

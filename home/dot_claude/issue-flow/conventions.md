# issue-flow 共通規約

GitHub ISSUE を軸に開発を進める skill 群(`issue-setup` / `issue-roadmap` / `issue-plan` /
`issue-refine` / `issue-implement` / `issue-review` / `issue-run` / `wiki-tidy`)が共有する決まり。
各 skill は最初にこのファイルを読む。

スクリプトは `~/.claude/issue-flow/scripts/` にある(以下 `$S` と書く)。
すべて対象リポジトリの中で実行する。

## 0. 冒頭で必ず行うこと

```sh
sh ~/.claude/issue-flow/scripts/check.sh
```

NG があれば**その場で直さず**、何が足りないかを示して `issue-setup` を案内し、止まる。
初期化処理は `issue-setup` にしか書かない(各 skill に散らすと、片方だけ直して
ずれるため)。WARN は内容を読んで従う(PUBLIC の警告など)。

## 1. 情報の置き場所

| 情報 | 置き場所 |
|---|---|
| ビジョン・テーマの順序・やらないこと・技術方針 | Wiki の `Roadmap` ページ |
| 再利用できる知見(コード構造、ハマりどころ、外部仕様) | Wiki のトピックページ |
| テーマ単位の目的・完了の定義・設計の大枠 | エピック ISSUE(`epic` ラベル) |
| 個別タスクの受け入れ条件・実装方針・対象ファイル | 個別 ISSUE の本文 |
| 状態 | `status:*` ラベルが正。Project の Status は追従 |

同じことを2か所に書かない。片方にはリンクだけ置く。

## 2. ISSUE の階層と関係

- **エピック**(`epic`): テーマ1つにつき1件。`status:*` は付けない
  (進捗はサブ ISSUE の消化で見る)。個別 ISSUE はサブ ISSUE としてぶら下げる
- **個別 ISSUE**: 下記テンプレートに従う。エピックに属さない単発のもの(バグ報告等)もある
- **依存**: 「#12 が終わらないと着手できない」は blocked by で登録する
  (`gh issue edit <N> --add-blocked-by 12`)。本文に「#12 の後」と書くだけで済ませない
- `status:blocked` は **GitHub の外の要因**(上流の修正待ち、ユーザーの判断待ちなど)専用。
  付けるときは理由をコメントする

よく使うコマンド:

```sh
gh issue create --title ... --body-file ... --label enhancement,priority:high --parent <エピック番号>
gh issue edit <エピック> --add-sub-issue 123,124
gh issue edit <N> --add-blocked-by 12
gh issue view <N> --json title,body,labels,parent,subIssues,blockedBy,comments
```

`gh issue view/list` の `--json` に `projectItems` を含めると project スコープが要る。
状態はラベルで読めば足りるので、通常は含めない。

## 3. ラベル

| 系統 | ラベル |
|---|---|
| 状態 | `status:triage` → `status:needs-refine` → `status:needs-approval` → `status:ready` → `status:in-progress` → `status:in-review` → `status:approved` / 例外 `status:blocked` |
| 優先度 | `priority:critical`(すぐ対応)/ `priority:high`(次にやる)/ `priority:medium`(そのうち)/ `priority:low`(余裕があれば) |
| 種別 | `bug` / `enhancement` / `documentation`(GitHub 既定)/ `chore` / `refactor` / `epic` |
| サイズ | `size:S`(1セッション)/ `size:M`(数セッション)/ `size:L`(分割を検討) |
| 自動実行 | `flow:running`(`issue-run` がエージェントを起動中。付け外しは `issue-run` だけが行う) |

個別 ISSUE には状態・優先度・種別を必ず1つずつ付ける。サイズは refine が付ける。

**状態の変更は必ずスクリプト経由**(ラベルと Project の Status を同時に変えるため):

```sh
sh ~/.claude/issue-flow/scripts/set-status.sh <N> <triage|needs-refine|needs-approval|ready|in-progress|in-review|approved|blocked>
```

`gh issue edit --add-label status:...` を直接使わない。

### 人間が持つ遷移

次の2つは **skill が行わない**。人間の判断を通すための関所なので、例外を作らない:

- `needs-approval` → `ready`(方針の承認)。skill は提案を書いて `needs-approval` で止まる。
  人間が承認したら `ready` にする。直してほしい点はコメントで返し、`needs-refine` に戻す
  (refine がコメントを反映して再提案する)
- `approved` → マージ・close(§6)

### 差し戻しの上限

review が実装の不備で `in-progress` に差し戻すのは、1つの PR につき **2回まで**。
3回目の不合格では差し戻さず、経緯をコメントして `blocked` にする
(同じ指摘の往復を自動で続けさせないため)。回数は PR 上の判定コメントの見出し
`## issue-review 判定: 不合格` の数で数える。

### 計画の見直しと進行中の ISSUE

`issue-roadmap` / `issue-plan` で計画を見直すとき、**`in-progress` / `in-review` /
`approved` の ISSUE は状態も本文も変えない**(実装・レビューが進行中で、横から書き換えると
食い違うため)。影響を受けそうなものは変更報告に「影響あり」として並べるだけにし、
扱いはマージの判断のときに人間が決める。`ready` 以前のものは見直しの対象に含める。
マージで close された ISSUE は Project 側の組み込みワークフローが Done にする。
対応しないと決めたものは理由をコメントして `gh issue close <N> --reason "not planned"`。

## 4. 個別 ISSUE の本文テンプレート

見出しは固定。各フェーズが担当のセクションを埋める。空のセクションも見出しは残す。

```markdown
親エピック: #<番号>(無ければ「なし」)

## 背景・目的
<!-- issue-plan: なぜやるのか。誰が何に困っているか -->

## 受け入れ条件
<!-- issue-plan: 検証可能な条件をチェックリストで。review はこれで合否を決める -->
- [ ] ...

## 調査結果
<!-- issue-refine: 要点だけ。詳しい知見は Wiki に書いてリンクする -->

## 実装方針
<!-- issue-refine: 何をどう変えるか。選ばなかった案とその理由も一言 -->

## 変更対象ファイル
<!-- issue-refine: パスと変更内容の概要 -->

## テスト方針
<!-- issue-refine: 何で検証するか。実行するコマンド -->

## スコープ外
<!-- issue-refine: やらないこと。見つけた別問題はフォローアップ ISSUE へ -->

## 未決事項
<!-- issue-refine: 残っている間は status:needs-approval にしない -->
```

**基準: 別セッションの Sonnet が、この本文だけ読めば迷わず実装できること。**
会話の文脈・「さっきの件」のような参照に頼らない。

## 5. Wiki

書き込み先は毎回スクリプトで解決する:

```sh
sh ~/.claude/issue-flow/scripts/wiki-path.sh
# → <wiki|docs> <TAB> <ローカルのパス> <TAB> <ページ URL の接頭辞>
```

- `wiki`: GitHub Wiki の作業コピー。編集後にその中で `git add -A && git commit && git push`
- `docs`: リポジトリ内の `docs/wiki/`。ファイル名は `<ページ名>.md`。コミットはするが
  push はしない(リポジトリの通常の運用に従う)

ページ構成:

| ページ | 内容 |
|---|---|
| `Home` | 索引。全ページへのリンクと一行説明 |
| `_Sidebar` | (wiki のみ)主要ページへのリンク |
| `Roadmap` | ビジョン / 現在のフェーズ / テーマとエピック(順序つき)/ やらないこと / 技術方針・制約 / 改訂履歴 |
| トピックページ | `Architecture`、`Gotchas`、`Ext-<外部サービス名>` など、話題ごと |

- **ISSUE ごとのページは作らない。** 知見は話題で整理する
- 書くのは**その ISSUE を超えて役立つことだけ**。その ISSUE でしか意味が無いことは本文へ
- 各記述に出典 ISSUE の**フル URL** を付ける(Wiki では `#123` が自動リンクされない)。
  逆に ISSUE 本文からは Wiki ページへリンクする
- ページを足したら `Home`(と `_Sidebar`)にも載せる
- `Roadmap` を変えたら改訂履歴に「日付・何を変えたか・きっかけ」を1行追記する

## 6. ブランチ・worktree・PR

- ブランチ名: `feature/<N>`。`bug` ラベルの ISSUE は `fix/<N>`
- worktree は `.claude/worktrees/<N>` に作り、`EnterWorktree` の `path` で入る
  (`name` で作るとブランチ名を指定できないため):

  ```sh
  git fetch origin
  git worktree add .claude/worktrees/<N> -b feature/<N> origin/<既定ブランチ>
  grep -qxF '.claude/worktrees/' .git/info/exclude 2>/dev/null || echo '.claude/worktrees/' >> .git/info/exclude
  ```

  既に存在すれば作らずにそのまま入る
- PR 本文の先頭に `Closes #<N>`。タイトルは ISSUE のタイトルに準じる
- **マージと ISSUE の close は人間が行う。** skill はマージしない

## 7. フォローアップ起票

作業中に見つけたスコープ外の問題は**その場で直さない**。

1. `gh issue create` で別 ISSUE を作る。本文冒頭に「<元 ISSUE の URL> から派生」、
   ラベルは種別と `priority:*`(判断できなければ `priority:medium`)
2. `set-status.sh <新番号> triage`
3. 元の ISSUE(または PR)に、起票したことをコメントする

## 8. 公開リポジトリへの配慮

`check.sh` が PUBLIC と出したリポジトリでは、ISSUE・PR・コメント・**Wiki** に
ホスト名・IP アドレス・ユーザー名・シリアル番号・ログやダンプの生の貼り付けを書かない。
どうしても必要なら**書き込まずに止めて**ユーザーに確認する。
(GitHub への書き込みは自律で行ってよいが、これだけは例外)

秘密(鍵・トークン・パスワード)はリポジトリの公開範囲に関係なく一切書かない。

## 9. 変更報告

各 skill の最後に、GitHub と Wiki に対して行った変更を一覧で示す。

```markdown
### 変更したもの
| 対象 | 内容 | リンク |
|---|---|---|
| #123 | 起票(enhancement, priority:high, status:needs-refine) | <URL> |
| #120 | 本文の「実装方針」ほかを更新、status:needs-approval | <URL> |
| Wiki: Gotchas | 「○○の制約」を追記 | <URL> |
| PR #130 | 作成(Closes #123) | <URL> |
```

変更が無かった場合も「変更なし」と明記する。

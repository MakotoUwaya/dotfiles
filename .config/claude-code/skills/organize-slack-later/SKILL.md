---
name: organize-slack-later
description: Slack の Later（保存項目）を整理し、自分タスク / 待ち / 保留 に分類して Obsidian の残タスク.md に集約する。Later が肥大化して優先度の高いものに気付けないときに使う。「Later 整理」「Slack 後で 整理」「Later 棚卸し」で起動。
---

# Organize Slack Later

## Overview

Slack の Later（保存項目）を一括レビューし、自分が今すぐ動くものだけを Later に残し、それ以外を Obsidian の残タスク.md にプロダクト軸で集約する。Later をリマインダ本来の用途（短期アクションリスト）に戻すためのワークフロー。

## When to Use

- 「Later 整理」「Later 棚卸し」「Slack 後で 整理」等の指示
- 月次〜四半期で Later が肥大化したとき
- 「優先度の高いものが見えない」「Later が常に通知点灯している」と感じたとき

## 前提と制約

- **Slack MCP には Later（保存項目）を一覧取得する API がない**ため、ユーザーから Later のリンクリストを貼ってもらうのが必須
- **Later の物理削除はユーザー手作業**。Skill 側は「残す / 外す」リストを出力するに留める
- **ヴォールトのパス解決と git 操作は `Bash` ツールで行う。** Windows でも Git Bash 経由で動作することを確認済み。PowerShell 版は検証していないため用意しない
- ヴォールトルートの解決順（**ヴォールトを操作する各コマンドブロックは、この解決順を使って単体で実行できる形にする。生の `$ES_OBSIDIAN_VAULT` を直接コマンドに書かない。`Bash` ツールは呼び出しごとにシェル状態がリセットされるため、前のブロックで解決した `$VAULT` は次の呼び出しに引き継がれない — 各コマンド例は毎回この解決順を再掲した自己完結ブロックにする**）:
  1. 環境変数 `ES_OBSIDIAN_VAULT`
  2. 未設定なら `~/.claude/vault-path.txt` の1行目

  bash での解決（参考。実際にはこれを埋め込んだ下記の自己完結ブロックを使う）:
  ```sh
  VAULT="${ES_OBSIDIAN_VAULT:-$(head -1 ~/.claude/vault-path.txt 2>/dev/null)}"
  [ -n "$VAULT" ] && [ -d "$VAULT" ] || { echo "ヴォールトルートを解決できません。ES_OBSIDIAN_VAULT か ~/.claude/vault-path.txt を確認してください"; exit 1; }
  ```

- 残タスク.md の場所: `<VAULT>/Daily/残タスク.md`（`Read`/`Write` ツールには上記の解決順で得た絶対パス文字列を渡す。両ツールともシェル変数展開はしないため、`$VAULT` という文字列のままでは渡さないこと）
- 日報の場所: `<VAULT>/Daily/YYYY/MM/YYYY-MM-DD.md`

> `GIT_SSH_COMMAND` はスキル側で設定しないこと。ヴォールトの remote は `core.sshCommand` を設定済みで、`GIT_SSH_COMMAND` を設定するとそれを上書きして push が失敗する。

## 残タスク.md の構造

```markdown
## 自分タスク

### ライセンスサーバ
- [ ] [タスク名](slack-link)
	- 依頼者・要点・期限のサマリ

### Square
### 売買
### SFA
### One
### Other（運用・基盤）

## 待ち
- [ ] [タスク名](slack-link) 依頼者
	- サマリ

## 保留（個別確認）
- [ ] [タスク名](slack-link) 依頼者（日付）
	- 判断つかない理由
```

プロダクト軸は日報と同じ分類（ライセンスサーバ / Square / 売買 / SFA / One / Other）。日報を確認してから揃える。

## 判定基準

| 区分 | 基準 |
|------|------|
| **Later に残す** | 自分が今すぐ動かないと進まないもののみ |
| **自分タスク** | 自分ボール・継続案件・調査・運用改善 |
| **待ち** | 他者ボール、依頼済み、要望提出のみ、確定待ち |
| **保留** | 自分 / 他者の判定がつかない、コンテキスト不明、状況確認要 |
| **削除（残タスクにも入れない）** | 情報共有のみでアクション不要、すでに完了済み |

## Instructions

### 0. ヴォールト同期の状態を確認

このスキルは `残タスク.md` を全体書き換えする。同期が止まったまま書き込むともう一方の機と食い違うため、冒頭で状態を確認する。**このスキルはユーザーグローバルで、どのリポジトリからでも起動される。** works の SessionStart hook は works のセッションでしか鳴らないので、ここでの確認が唯一の検知経路になることがある:

```sh
CHECK="$HOME/ghq/gitlab.com/eseikatsu/sandbox/m-uwaya/works/scripts/vault-sync/check-state.sh"
[ -f "$CHECK" ] && bash "$CHECK" || echo "[警告] check-state.sh が見つかりません: $CHECK"
```

- **出力が無ければ正常**。そのまま Step 1 へ進む
- **警告が出たら、その内容をそのままユーザーに提示し、先に進んでよいか確認する。**`conflict` の場合は `/vault-sync-resolve` での解決を先に済ませる

### 1. 入力受領

ユーザーに Later のリンクを以下のフォーマットで貼ってもらう：

```
1. <Slackリンク> | 一言メモ（任意）
2. <Slackリンク> | ...
```

Slack の Later タブでアイテムを選んで「リンクをコピー」できる。スクリーンショット OCR は誤認識が出るため非推奨。

### 2. Slack 本文取得

各リンクから `channel_id`, `message_ts`, `thread_ts` を抽出し、`mcp__claude_ai_Slack__slack_read_thread` で並列取得する。

- バッチサイズ: 8 件並列が現実的（context 膨張と Slack レート制限のバランス）
- `response_format: "concise"` を指定して context 消費を抑える
- スレッド付きリンク（`?thread_ts=...` あり）は `message_ts` に **`thread_ts`** を渡す（親メッセージから読む）
- スレッドなしのリンクは `message_ts` をそのまま渡す
- エラー（`Anthropic Proxy: Invalid content from server` 等）は 1〜2 回再試行

リンクパースの URL パターン:
- `https://eseikatsu.slack.com/archives/<channel_id>/p<ts_concat>?thread_ts=<thread_ts>&cid=...`
- `p1234567890123456` → `1234567890.123456`（10 桁 + 6 桁にドット挿入）

### 3. 分類

各メッセージから以下を抽出:

- 依頼者（最初に発言した人 or `[]` 内の名前）
- プロダクト（チャンネル名・本文から推定。日報の分類軸に揃える）
- 要点（何をすべきか）
- 期限の手がかり（日付、リリースタイミング）
- 自分 / 他者 / 曖昧 の判定

判定がつかないものは無理に決めず **保留** に集める。

### 4. 既存残タスク.md との突合

- `Read` で既存の残タスク.md を読み込む
- 既存項目で同じ話題のものがあればマージ（重複させない）
- 既存項目の中で古い・終了したものがあれば削除候補として提示

### 4.5 ヴォールトを最新化

書き換え前に必ず pull する。他機が同じファイルを更新している可能性があるため。解決からコマンドまでを1回の `Bash` 呼び出しで完結させる:

```sh
VAULT="${ES_OBSIDIAN_VAULT:-$(head -1 ~/.claude/vault-path.txt 2>/dev/null)}"
[ -n "$VAULT" ] && [ -d "$VAULT" ] || { echo "ヴォールトルートを解決できません。ES_OBSIDIAN_VAULT か ~/.claude/vault-path.txt を確認してください"; exit 1; }
cd "$VAULT" && git pull --rebase
```

**この pull が失敗したら、その場で中断してユーザーに報告する。`残タスク.md` の書き換えには進まない。** 失敗したまま書き込むと、古いベースの上に全体書き換えをかけることになり、もう一方の機の追加項目を丸ごと消す。作業ツリーが汚れている・同期が競合で止まっている等が典型なので、`/vault-sync-resolve` を案内する。

### 5. 残タスク.md を Write で書き直し

`Write` ツールで全体を書き換える（部分編集ではなく完全書き換えのほうが構造が崩れにくい）。`file_path` には 4.5 で解決した `$VAULT` と同じ解決順で得た絶対パス文字列を渡す（`Write` はシェル変数展開をしないため、`$VAULT` という文字列のままでは渡さないこと）。

転記フォーマット:
```markdown
- [ ] [短いタスク名](slack-link)
	- 依頼者: XX さん
	- 要点・期限・状況のサマリ（2〜3 行）
```

待ち / 保留セクションでは依頼者を見出し横にも書く:
```markdown
- [ ] [タスク名](slack-link) 依頼者名
	- サマリ
```

書き換え後は即座に反映する。`git add` と `git commit` は別々の `Bash` 呼び出しにするが、それぞれを自己完結ブロックにする:

```sh
VAULT="${ES_OBSIDIAN_VAULT:-$(head -1 ~/.claude/vault-path.txt 2>/dev/null)}"
[ -n "$VAULT" ] && [ -d "$VAULT" ] || { echo "ヴォールトルートを解決できません。ES_OBSIDIAN_VAULT か ~/.claude/vault-path.txt を確認してください"; exit 1; }
cd "$VAULT" && git add Daily/残タスク.md
```

```sh
VAULT="${ES_OBSIDIAN_VAULT:-$(head -1 ~/.claude/vault-path.txt 2>/dev/null)}"
[ -n "$VAULT" ] && [ -d "$VAULT" ] || { echo "ヴォールトルートを解決できません。ES_OBSIDIAN_VAULT か ~/.claude/vault-path.txt を確認してください"; exit 1; }
cd "$VAULT" && git commit -m "残タスク整理: YYYY-MM-DD" && git push
```

### 6. Later 操作リスト出力

ユーザーに以下を別途提示（残タスク.md には書かない）:

```
### Later に残す件
（自分が今すぐ動くもののみ。基本的にゼロ件になることが多い）

### Later から外して OK な件
N. <channel>/p<ts>   <短い見出し>
...

### 削除推奨（残タスクにも入れない）
N. ...   理由
```

### 7. ユーザー判断ステップ

最後に以下を案内:

1. 残タスク.md を `/difit` または Obsidian でレビュー
2. `## 保留` セクションを一緒に個別判断
3. Slack で Later から該当件を手作業で外す

## Examples

### 起動例

```
ユーザー: Later 整理して
Skill: Slack の Later のリンクを以下のフォーマットで貼ってください…

ユーザー: <30 件のリンク>
Skill: バッチで Slack 本文を取得 → 分類 → 残タスク.md 更新 → Later 操作リスト出力
```

### 1 件の処理イメージ

入力:
```
https://eseikatsu.slack.com/archives/C022VDTV606/p1727949279323999?thread_ts=1727679758.130879&cid=C022VDTV606
```

出力（残タスク.md > 自分タスク > 売買）:
```markdown
- [ ] [SFA Issue#4390 メッセージプレビュー反映 - エラーコード方針](https://eseikatsu.slack.com/archives/C022VDTV606/p1727949279323999?thread_ts=1727679758.130879&cid=C022VDTV606)
	- 藤ノ木さんと検討。`mail-*` `line-*` は表示維持、`communication-*` `common-*` はフロントでフィルタ方針。OneAPI 修正必要
```

## Guidelines

- **Later に残すバーは高く保つ**: 「自分が今すぐ動くもののみ」を厳格に適用しないと、整理しても結局 Later が肥大化する
- **待ちと自分タスクを混ぜない**: 残タスク.md の `## 自分タスク` には自分ボールのものだけ。他者ボールは `## 待ち` に隔離
- **保留を恐れない**: 判定に迷ったらまず保留へ。後でユーザーと一緒に判断する方が誤判定の手戻りより安い
- **既存残タスク.md は同時に棚卸し**: Later 整理のついでに、既存項目で古いもの・完了したものも見直す
- **Slack MCP の制約を覚えておく**: Later 一覧取得 API はない。`stars.list` / `saved.list` 系は MCP に未公開
- **大量並列 read は context を圧迫**: 30+ 件の thread を一度に読むと context が肥大化するので、`concise` + バッチ + 要点メモで圧縮する
- **転記時の自動サマリは Slack 本文ベース**: 推測で補わない。本文に書かれている内容のみ要約する

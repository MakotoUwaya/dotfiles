---
name: glab
description: GitLab CLI の読み取り操作専用。MR・イシュー・パイプラインの一覧表示・詳細確認に使用。作成・マージ・承認等の書き込み操作は禁止
---

# GitLab CLI (glab)

glab は GitLab の公式 CLI ツールです。MR、イシュー、CI/CD パイプラインなどを操作できます。

## When to Use

- MR の一覧表示・詳細確認・差分表示
- イシューの一覧表示・詳細確認
- CI/CD パイプラインの状態確認・ジョブログ表示

## Prohibited Operations

以下の操作は禁止です。このスキルを使って実行しないでください:

- MR の作成・マージ・承認
- イシューの作成・クローズ
- パイプラインの実行・キャンセル
- その他の書き込み操作

### 書き込み操作にあたるコマンド

- `glab mr create` - MR 作成
- `glab mr merge` - MR マージ
- `glab mr approve` / `glab mr revoke` - MR 承認・取消
- `glab mr update` - MR 更新
- `glab mr close` / `glab mr reopen` - MR クローズ・リオープン
- `glab mr note` - MR コメント
- `glab issue create` - イシュー作成
- `glab issue update` - イシュー更新
- `glab issue close` / `glab issue reopen` - イシュークローズ・リオープン
- `glab issue note` - イシューコメント
- `glab ci run` - パイプライン実行
- `glab ci cancel` - パイプラインキャンセル
- `glab ci retry` - パイプラインリトライ
- `glab ci delete` - パイプライン削除
- `glab release create` - リリース作成

**書き込み操作が必要な場合:** コマンドを直接実行せず、ユーザーに「このコマンドを実行してください」とコマンドを提示してください。

## 認証

```bash
# ログイン
glab auth login

# 認証状態確認
glab auth status
```

## マージリクエスト (MR)

### MR 一覧・確認

```bash
# MR一覧
glab mr list
glab mr list --state=opened
glab mr list --state=merged
glab mr list --assignee=@me
glab mr list --reviewer=@me

# MR詳細表示
glab mr view <mr-id>
glab mr view <mr-id> --web    # ブラウザで開く

# MR差分表示
glab mr diff <mr-id>
```

### MR 作成

```bash
# 対話的に作成
glab mr create

# オプション指定で作成
glab mr create --title "feat: add new feature" \
               --description "Description here" \
               --target-branch main

# ドラフトMR作成
glab mr create --draft

# WIP MR作成
glab mr create --wip

# 自動マージ設定
glab mr create --squash-before-merge

# ラベル・アサイン指定
glab mr create --label "bug,priority::high" \
               --assignee "username" \
               --reviewer "reviewer1,reviewer2"
```

### MR 操作

```bash
# チェックアウト
glab mr checkout <mr-id>

# マージ
glab mr merge <mr-id>
glab mr merge <mr-id> --squash
glab mr merge <mr-id> --when-pipeline-succeeds

# 更新
glab mr update <mr-id> --title "new title"
glab mr update <mr-id> --assignee "username"
glab mr update <mr-id> --label "label1,label2"

# クローズ/リオープン
glab mr close <mr-id>
glab mr reopen <mr-id>

# 承認
glab mr approve <mr-id>
glab mr revoke <mr-id>

# コメント
glab mr note <mr-id> --message "LGTM!"
```

## イシュー

### イシュー一覧・確認

```bash
# イシュー一覧
glab issue list
glab issue list --state=opened
glab issue list --assignee=@me
glab issue list --label="bug"

# イシュー詳細
glab issue view <issue-id>
glab issue view <issue-id> --web
```

### イシュー作成・操作

```bash
# 対話的に作成
glab issue create

# オプション指定で作成
glab issue create --title "Bug: something broken" \
                  --description "Description" \
                  --label "bug,priority::high" \
                  --assignee "username"

# イシュー更新
glab issue update <issue-id> --title "new title"
glab issue update <issue-id> --label "label1,label2"

# クローズ/リオープン
glab issue close <issue-id>
glab issue reopen <issue-id>

# コメント
glab issue note <issue-id> --message "Working on this"
```

## CI/CD パイプライン

### パイプライン確認

```bash
# パイプライン一覧
glab ci list

# 最新パイプラインの状態
glab ci status

# パイプライン詳細
glab ci view <pipeline-id>

# パイプラインをブラウザで開く
glab ci view --web
```

### パイプライン操作

```bash
# パイプライン実行
glab ci run
glab ci run --branch <branch>
glab ci run --variables "KEY1:value1,KEY2:value2"

# パイプラインキャンセル
glab ci cancel <pipeline-id>

# パイプラインリトライ
glab ci retry <pipeline-id>

# パイプライン削除
glab ci delete <pipeline-id>
```

### ジョブ操作

```bash
# ジョブ一覧
glab ci list --jobs

# ジョブログ表示
glab ci trace <job-id>

# ジョブリトライ
glab ci retry --job <job-id>

# アーティファクトダウンロード
glab ci artifact <job-id>
```

## CI Lint

```bash
# .gitlab-ci.yml の検証
glab ci lint
glab ci lint .gitlab-ci.yml

# 詳細出力
glab ci lint --include-jobs
```

## API アクセス

```bash
# GET リクエスト
glab api projects/:id
glab api projects/:id/merge_requests

# POST リクエスト
glab api projects/:id/issues --method POST \
     --field title="New Issue" \
     --field description="Description"

# レスポンスをフォーマット
glab api projects/:id | jq '.name'

# ページネーション
glab api projects/:id/merge_requests --paginate
```

## リポジトリ操作

```bash
# リポジトリをクローン
glab repo clone <owner/repo>

# リポジトリ情報
glab repo view
glab repo view --web

# フォーク
glab repo fork <owner/repo>
```

## その他

```bash
# 設定
glab config set editor vim
glab config set browser firefox

# エイリアス
glab alias set pv 'mr view'
glab alias list

# ラベル一覧
glab label list

# マイルストーン一覧
glab milestone list

# リリース
glab release list
glab release create <tag> --notes "Release notes"
```

## 便利な使い方

```bash
# 自分がアサインされたMRとイシューを確認
glab mr list --assignee=@me
glab issue list --assignee=@me

# レビュー待ちのMR確認
glab mr list --reviewer=@me

# 現在のブランチのMRを開く
glab mr view --web

# CIの状態を監視
watch -n 30 glab ci status

# MR作成からマージまで
glab mr create --fill
glab ci status --wait
glab mr merge --when-pipeline-succeeds
```

---
name: gitlab-api
description: GitLab の操作（MR、Issue、パイプライン等）を行う際に自動適用される。MCP ツール (mcp__claude_ai_GitLab__*) や glab CLI の使い分け、API 呼び出しのパターンと注意点を提供する。
user-invocable: false
---

# GitLab API 操作ガイド

## Overview

GitLab の MCP ツールと glab CLI の使い分け、および API 呼び出し時の注意点をまとめる。

## When to Use

- GitLab の MR・Issue・パイプライン等を操作するとき
- MCP ツールと glab CLI のどちらを使うか判断が必要なとき
- glab api でドラフトノートやインラインコメントを投稿するとき

## Instructions

### MCP ツールを使う場面

以下は MCP ツールが提供しており、構造化されたデータを取得できる:

| 操作 | MCP ツール |
|---|---|
| Issue 取得 | `get_issue` |
| Issue 作成 | `create_issue` |
| MR 取得 | `get_merge_request` |
| MR 作成 | `create_merge_request`（※ 複数行 description は glab CLI 推奨） |
| MR コミット一覧 | `get_merge_request_commits` |
| MR 差分 | `get_merge_request_diffs` |
| MR パイプライン | `get_merge_request_pipelines` |
| パイプラインジョブ | `get_pipeline_jobs` |
| 検索 | `search` |
| コード検索（自然言語） | `semantic_code_search` |
| ラベル検索 | `search_labels` |
| Work Item コメント取得 | `get_workitem_notes` |
| Work Item コメント作成 | `create_workitem_note` |

### glab CLI を使う場面

以下のケースでは `glab` CLI を優先する:

- **MCP にない操作**: ドラフトノート、Approve、MR マージなど
- **簡易な確認**: `glab mr view`、`glab issue view` は出力が読みやすく速い
- **REST API 直接呼び出し**: `glab api` で任意のエンドポイントにアクセス可能
- **出力の加工**: パイプでの `jq` 連携が容易

### 判断基準

1. MCP ツールで実現できるならまず MCP を使う（ツール呼び出しの方が構造化データを扱いやすい）
2. MCP で不足する場合は `glab` CLI にフォールバック
3. 単純な確認や一覧取得は `glab` の方が速い場合もあるので柔軟に判断

### MCP ツールの制限事項: 複数行テキスト

**MCP ツールの文字列パラメータでは `\n` がリテラル文字列として扱われ、実際の改行にならない。**

以下の操作では **`glab` CLI + ヒアドキュメント** を使うこと:

- MR 作成・更新（`description` に Markdown を含む場合）
- Issue 作成・更新（`description` に Markdown を含む場合）
- 複数行のコメント投稿

```bash
# MR 作成（正しい方法）
glab mr create --title "タイトル" --description "$(cat <<'EOF'
## Summary

変更の概要をここに記述。

## 変更内容
- 項目1
- 項目2
EOF
)"

# MR description の更新
glab mr update <MR番号> --description "$(cat <<'EOF'
## Summary

更新後の説明文。
EOF
)"
```

**注意**: 単一行の description であれば MCP ツールでも問題ない。

---

## glab api コマンドのパターン

### 基本

```bash
# GET（デフォルト）
glab api "projects/:id/merge_requests/123"

# POST
glab api "projects/:id/merge_requests/123/draft_notes" \
  --method POST --raw-field "note=コメント本文"

# PUT
glab api "projects/:id/issues/456" \
  --method PUT --raw-field "state_event=close"
```

`:id` は現在のプロジェクト ID に自動置換される。

### ネストされたパラメータの送信

`--raw-field` ではネストされた JSON パラメータ（`position.base_sha` 等）を正しく送信できない。
**JSON ファイル + `--input` を使うこと。**

```bash
python3 -c "
import json
body = {
    'note': 'コメント本文',
    'position': {
        'base_sha': '<base_sha>',
        'head_sha': '<head_sha>',
        'start_sha': '<start_sha>',
        'new_path': 'path/to/file.rb',
        'old_path': 'path/to/file.rb',
        'position_type': 'text',
        'new_line': 42
    }
}
with open('/tmp/api_body.json', 'w') as f:
    json.dump(body, f, ensure_ascii=False)
" && glab api "projects/:id/merge_requests/<MR番号>/draft_notes" \
  --method POST --input /tmp/api_body.json -H "Content-Type: application/json"
```

---

## ページネーション

GitLab REST API はデフォルトで **20 件** しか返さない。

- 一覧系の API には `per_page=100` を指定する
- レスポンスヘッダの `x-next-page` を確認し、値があれば次ページを取得する
- MCP ツールの `page` / `per_page` パラメータも同様に活用する

```bash
# ページネーション付き取得
glab api "projects/:id/merge_requests/123/discussions?per_page=100"
```

---

## ドラフトノート（Review Mode）

MR へのレビューコメントは **ドラフトノート** で投稿する。投稿者が GitLab GUI で確認・確定するワークフロー。

### 一般コメント（MR 全体）

```bash
glab api "projects/:id/merge_requests/<MR番号>/draft_notes" \
  --method POST --raw-field "note=コメント本文"
```

### インラインコメント（特定の差分行）

まず `diff_refs` を取得:

```bash
glab api "projects/:id/merge_requests/<MR番号>" \
  | python3 -c "import json,sys; d=json.load(sys.stdin)['diff_refs']; print(d['base_sha'], d['head_sha'], d['start_sha'])"
```

JSON ファイル経由で投稿（前述「ネストされたパラメータの送信」を参照）:

- `new_line`: 追加行（`+` 行）にコメントする場合
- `old_line`: 削除行（`-` 行）にコメントする場合

**新規ファイル (new file) への投稿**: `old_path` は `new_path` と同じパスを指定する（省略しても受理される）。`old_line` は `null` のままで良い。GitLab API はどちらでも valid な position として受理し、`line_code` を生成する。

### インラインドラフトが UI で見えないとき

投稿が API レスポンスで成功 (200) し、`line_code` が生成されていても、GitLab の Changes タブで対象行にドラフトが表示されないことがある（`.claude/` 配下、`*.lock`、生成物ディレクトリ等の auto-collapse 対象ファイル）。**Submit review 一覧（右上のレビューパネル）には表示されるので、投稿自体は成立している。**

対処は以下の順で試す。**最初から一般ドラフトに退避しないこと**:

1. **API で position が valid か確認**: `glab api .../draft_notes/<id>` で `line_code` が生成されているかチェック
2. **Submit review 一覧で見えているか確認**: 表示されていれば投稿は成立。ユーザーに Changes タブの **ファイル展開** と **ハードリロード (Ctrl+Shift+R)** を依頼する
3. **同じ position で DELETE → POST**: GitLab 側のキャッシュ更新を狙う
4. **最終手段としてのみ一般ドラフトに切り替え**: 本文冒頭に `` `path/to/file:LINE` `` を明記して再投稿する

**「見えない＝間違っている」と早合点して退避しない**。退避すると Author 側で対象行が ambiguous になり、結局 Author が GUI でインラインに付け直す手間が発生する。

### 既存ディスカッションへの返信

通常の `discussions/:id/notes` API ではなく、ドラフトノートの `in_reply_to_discussion_id` パラメータを使う:

```bash
glab api "projects/:id/merge_requests/<MR番号>/draft_notes" \
  --method POST \
  --raw-field "note=返信内容" \
  --raw-field "in_reply_to_discussion_id=<discussion_id>"
```

---

## Examples

### 一般コメントの投稿

```bash
glab api "projects/:id/merge_requests/<MR番号>/draft_notes" \
  --method POST --raw-field "note=コメント本文"
```

### インラインコメントの投稿（JSON ファイル経由）

```bash
python3 -c "
import json
body = {
    'note': 'コメント本文',
    'position': {
        'base_sha': '<base_sha>',
        'head_sha': '<head_sha>',
        'start_sha': '<start_sha>',
        'new_path': 'path/to/file.rb',
        'old_path': 'path/to/file.rb',
        'position_type': 'text',
        'new_line': 42
    }
}
with open('/tmp/api_body.json', 'w') as f:
    json.dump(body, f, ensure_ascii=False)
" && glab api "projects/:id/merge_requests/<MR番号>/draft_notes" \
  --method POST --input /tmp/api_body.json -H "Content-Type: application/json"
```

## バッククォート・Markdown を含む body の投稿

`glab api -f "body=..."` や `--raw-field` で body にバッククォート（`` ` ``）を含めると、bash のエスケープで壊れる。
**Python subprocess 経由で投稿すること。**

```bash
python -c "
import subprocess, json

notes = [
    {'discussion': '<discussion_id>', 'body': 'バッククォート \`code\` を含む本文'},
]

for n in notes:
    url = f'projects/:id/merge_requests/<MR番号>/discussions/{n[\"discussion\"]}/notes'
    result = subprocess.run(
        ['glab', 'api', url, '-X', 'POST', '-f', f'body={n[\"body\"]}'],
        capture_output=True, text=True
    )
    resp = json.loads(result.stdout)
    print(f'Note {resp[\"id\"]}: OK')
"
```

ドラフトノートの場合も同様に `draft_notes` エンドポイントで Python 経由で投稿する。

## Guidelines

- **Approve / Request Changes**: REST API からはステータス変更できない。コメント本文で意図を伝える
- **ドラフトノートの確定**: API からは Submit review できない。ユーザーが GUI で確定する必要がある
- 一覧系の API には `per_page=100` を指定する（デフォルトは 20 件）
- `--raw-field` ではネストされた JSON を送信できない。JSON ファイル + `--input` を使うこと

---
name: gws
description: Gmail を gws CLI で操作する際のリファレンス。「gws」「gmail」「メール」で自動呼び出し。Google Calendar は MCP ツール (gcal_list_events 等) を使用すること。
---

# gws CLI リファレンス

> **注意**: Google Calendar は `mcp__claude_ai_Google_Calendar__gcal_list_events` 等の MCP ツールに移行済み。`gws calendar` は使わないこと。

## 認証

- `gws auth login` で OAuth2 認証（`gcloud auth` とは別管理）
- サービス追加: `gws auth login -s gmail --readonly`
- 書き込み権限が必要な場合: `gws auth login -s gmail`（`--readonly` なし）
- 認証状態確認: `gws auth status`
- トークンキャッシュの問題時: `~/.config/gws/token_cache.json` を削除して再認証

## Gmail

### メール検索

```sh
# q パラメータで検索（推奨）
gws gmail users messages list --params '{"userId": "me", "q": "label:xxx is:unread", "maxResults": 50}'
```

### メール詳細取得

```sh
# format: "full" でヘッダー（Subject, From, Date 等）が取得できる
gws gmail users messages get --params '{"userId": "me", "id": "<message_id>", "format": "full"}'
```

### メール既読化（batchModify）

```sh
# UNREAD ラベルを一括除去して既読にする
gws gmail users messages batchModify --params '{"userId": "me"}' --json '{"ids": ["id1", "id2"], "removeLabelIds": ["UNREAD"]}'
```

- **`--json` フラグを使うこと**（`--body` は存在しない）
- 書き込み権限が必要（`--readonly` 認証では失敗する）

### ヘルパーコマンド

```sh
# 未読メールのサマリ表示
gws gmail +triage
```

### 既知の注意事項

- `labelIds` パラメータは配列が文字列化されるバグがある → `q` パラメータでラベル検索すること
- `format: "metadata"` + `metadataHeaders` ではヘッダーが空になる場合がある → `format: "full"` を使う
- `resultSizeEstimate` は概算値で正確ではない → 正確な件数は全件取得して数える

## API スキーマ確認

```sh
# 任意の API のパラメータを確認
gws schema gmail.users.messages.list
```

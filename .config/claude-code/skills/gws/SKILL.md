---
name: gws
description: Google Workspace リソース（Gmail, Calendar, Drive 等）を gws CLI で操作する際のリファレンス。「gws」「gmail」「calendar」「メール」で自動呼び出し
---

# gws CLI リファレンス

## 認証

- `gws auth login` で OAuth2 認証（`gcloud auth` とは別管理）
- サービス追加: `gws auth login -s gmail,calendar --readonly`
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

### ヘルパーコマンド

```sh
# 未読メールのサマリ表示
gws gmail +triage
```

### 既知の注意事項

- `labelIds` パラメータは配列が文字列化されるバグがある → `q` パラメータでラベル検索すること
- `format: "metadata"` + `metadataHeaders` ではヘッダーが空になる場合がある → `format: "full"` を使う
- `resultSizeEstimate` は概算値で正確ではない → 正確な件数は全件取得して数える

## Calendar

```sh
# 予定取得
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "2026-03-07T00:00:00+09:00",
  "timeMax": "2026-03-07T23:59:59+09:00",
  "singleEvents": true,
  "orderBy": "startTime"
}'
```

## API スキーマ確認

```sh
# 任意の API のパラメータを確認
gws schema gmail.users.messages.list
```

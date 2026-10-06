# GCP アラート調査手順

Cloud Monitoring / Personalized Service Health 由来のアラートを調査するためのコマンド集。
`<project>` はアラートのリンク URL の `project=` パラメータから取得する。

## 前提確認

```sh
gcloud config get-value account   # 認証済みアカウントの確認
```

未認証、または `Reauthentication failed. cannot prompt during non-interactive execution` が出た場合はユーザーに `! gcloud auth login` の実行を依頼する。

プロジェクト ID は以下（gcloud の configuration 名 `es-account-prod` とは異なるので注意）:

| 環境 | プロジェクト ID |
|------|----------------|
| prod | `es-account` |
| stage | `es-account-stage` |
| dev | `es-account-dev` |

Service Health アラートは stage / prod で同時に発火することが多い。Slack 通知が片方のみでも両プロジェクトを確認する。

## 1. 発火元アラートポリシーの特定

```sh
# ポリシー一覧（表示名から発火元を推定）
gcloud alpha monitoring policies list --project=<project> \
  --format="table(name.basename(), displayName, enabled)"

# ポリシー詳細（発火条件・フィルタ・除外設定・documentation を確認）
gcloud alpha monitoring policies describe \
  projects/<project>/alertPolicies/<policy_id> --project=<project>
```

確認ポイント:

- `conditions[].conditionMatchedLog.filter` — ログ条件アラートのフィルタ。`NOT (...)` の denylist が入っていることがある
- `alertStrategy.autoClose` — 自動クローズまでの時間（緊急性評価に使う）
- `mutationRecord` — 最近ポリシーが変更されていないか

## 2. 発火時刻とイベントの突合

アラート発報時刻（Slack 表示は JST）を UTC に変換し（JST − 9 時間）、ポリシーのフィルタでログを検索する:

```sh
gcloud logging read '<ポリシーの filter をそのまま、または緩めて指定>' \
  --project=<project> --freshness=24h \
  --format="value(timestamp, resource.labels.event_id, jsonPayload.title)"
```

Service Health の場合はポリシーの filter を調べなくても、次のクエリで一発で突合できる（`ViolationOpenEventv1` の `violation_id` が Slack 通知リンクの `alerts/<id>` と一致する）:

```sh
gcloud logging read 'logName:"servicehealth" OR resource.type="servicehealth.googleapis.com/Event"' --project=<project> --freshness=2d \
  --format="value(timestamp, labels, jsonPayload.title, jsonPayload.state, jsonPayload.detailedState)"
```

発報ログ（logName `monitoring.googleapis.com/ViolationOpenEventv1`）は `resource.type` 側でしか拾えないため OR を外さない。
通知リンクの ID が分かっていれば `labels.violation_id="<id>"` で直接引ける。

発報時刻 ±数分のログエントリが対象イベント。
Service Health の場合は `labels."servicehealth.googleapis.com/new_event" = true` のエントリが新規発火に対応する。

## 3. イベントの現在状態確認

### Service Health イベント（GCP 側障害）

```sh
gcloud beta service-health events describe <EVENT_ID> \
  --project=<project> --location=global \
  --format="yaml(state, category, detailedState, updateTime, updates)"
```

- `detailedState: RESOLVED` / `state: CLOSED` なら解消済み
- `updates[]` の最後のエントリに解消時刻と原因（プロバイダ発表）が載る

### メトリクスしきい値アラート

平常時ベースラインを先に確認してから異常判定する:

`gcloud monitoring time-series` は存在しないため、Monitoring API を直接呼ぶ:

```sh
# 日次の点数で欠損・停止を確認（1 分間隔メトリクスなら平常 1440/日）
curl -s -G -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://monitoring.googleapis.com/v3/projects/<project>/timeSeries" \
  --data-urlencode 'filter=metric.type="<metric>"' \
  --data-urlencode "interval.startTime=<RFC3339>" \
  --data-urlencode "interval.endTime=<RFC3339>" \
  --data-urlencode "aggregation.alignmentPeriod=86400s" \
  --data-urlencode "aggregation.perSeriesAligner=ALIGN_COUNT" \
  | jq -r '.timeSeries[]? | .points[] | "\(.interval.endTime) \(.value.int64Value)"' | sort
```

aggregation を外して `jq '[.timeSeries[]?.points[].interval.endTime] | sort | .[-1]'` とすると最終データ点の時刻が取れる。
メトリクス欠損系の障害では、同インスタンスの別メトリクス（CPU 等）を対照として並べて取得する。

## 4. 実影響の証拠ベース確認

影響対象の操作が当該時間帯に実行されたかを監査ログで確認する:

```sh
# 例: Firestore の restore / clone 操作の有無
gcloud logging read 'protoPayload.serviceName="firestore.googleapis.com" AND
  (protoPayload.methodName:"RestoreDatabase" OR protoPayload.methodName:"CloneDatabase")' \
  --project=<project> --freshness=48h \
  --format="value(timestamp, protoPayload.methodName)"
```

確認ポイント:

- 影響リージョンに自システムのリソースがあるか（例: asia-northeast1 利用中なら us-east1 限定の障害は影響なし）
- 影響対象のサービス・操作を自システムが使っているか（未使用サービスなら実影響なし）
- stage / prod など複数プロジェクトで同じアラートが発火している場合は両方確認する

## 注意

- `gcloud alpha` / `gcloud beta` コンポーネントが必要なコマンドがある。未インストールエラー時は `gcloud components install alpha beta` をユーザーに依頼する
- Cloud Monitoring の incident 自体を取得する公開 API はない。incident ID からの直接照会はできないため、発火時刻とログの突合で対象イベントを特定する
